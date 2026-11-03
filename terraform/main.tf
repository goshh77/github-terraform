locals {
  name = "${var.name_prefix}-${var.environment}"

  common_labels = merge({
    environment = var.environment
    managed-by  = "terraform"
    repo        = "github-terraform"
  }, var.labels)

  # APIs required by the resources in this stack.
  required_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
  ]
}

############################
# Enable APIs
############################
resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

############################
# Service accounts for workloads (least privilege)
############################
module "iam" {
  source = "./modules/iam"

  project_id = var.project_id

  service_accounts = {
    "${local.name}-app-vm" = {
      display_name = "App VM (${var.environment})"
      roles        = [
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
        "roles/cloudsql.client",
      ]
    }
    "${local.name}-web-mig" = {
      display_name = "Web MIG instances (${var.environment})"
      roles        = [
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
      ]
    }
  }

  depends_on = [google_project_service.apis]
}

# Let named humans SSH into private VMs through IAP + OS Login.
locals {
  iap_bindings = {
    for pair in setproduct(var.iap_ssh_members, [
      "roles/iap.tunnelResourceAccessor",
      "roles/compute.osAdminLogin",
    ]) : "${pair[0]}|${pair[1]}" => { member = pair[0], role = pair[1] }
  }
}

resource "google_project_iam_member" "iap_ssh" {
  for_each = local.iap_bindings

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}

############################
# Network: VPC, subnets, NAT, firewall, private service access
############################
module "network" {
  source = "./modules/network"

  project_id          = var.project_id
  region              = var.region
  name                = local.name
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  psa_prefix_length   = var.psa_prefix_length

  depends_on = [google_project_service.apis]
}

############################
# Private application VM
############################
module "app_vm" {
  source = "./modules/compute"

  name                  = "${local.name}-app-vm"
  zone                  = var.zone
  machine_type          = var.app_vm_machine_type
  image                 = var.vm_image
  subnetwork_id         = module.network.private_subnet_id
  service_account_email = module.iam.emails["${local.name}-app-vm"]
  tags                  = ["ssh-iap", "app"]
  labels                = local.common_labels
}

############################
# Web tier: MIG behind a global HTTP load balancer
############################
module "web_mig" {
  source = "./modules/mig"

  name                  = "${local.name}-web"
  region                = var.region
  machine_type          = var.mig_machine_type
  image                 = var.vm_image
  subnetwork_id         = module.network.private_subnet_id
  service_account_email = module.iam.emails["${local.name}-web-mig"]
  min_replicas          = var.mig_min_replicas
  max_replicas          = var.mig_max_replicas
  cpu_target            = var.mig_cpu_target
  labels                = local.common_labels
}

module "lb" {
  source = "./modules/lb"

  name            = "${local.name}-web"
  instance_group  = module.web_mig.instance_group
  health_check_id = module.web_mig.health_check_id
}

############################
# Database: Cloud SQL (private IP only)
############################
module "database" {
  source = "./modules/database"

  name                = "${local.name}-pg"
  region              = var.region
  network_id          = module.network.network_id
  database_version    = var.db_version
  tier                = var.db_tier
  db_name             = var.db_name
  db_user             = var.db_user
  deletion_protection = var.deletion_protection
  labels              = local.common_labels

  # Static keys, so for_each works even before the SA emails are known.
  secret_accessors = {
    app_vm = "serviceAccount:${module.iam.emails["${local.name}-app-vm"]}"
  }

  # Cloud SQL private IP needs the VPC peering from the network module first.
  depends_on = [module.network]
}

############################
# Storage: application bucket
############################
module "app_bucket" {
  source = "./modules/storage"

  name          = "${var.project_id}-${var.environment}-app-data"
  location      = var.region
  force_destroy = !var.deletion_protection
  labels        = local.common_labels

  object_admins = {
    app_vm = "serviceAccount:${module.iam.emails["${local.name}-app-vm"]}"
  }

  depends_on = [google_project_service.apis]
}
