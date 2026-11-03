project_id  = "newprj-harsha"
environment = "dev"
region      = "asia-south1"
zone        = "asia-south1-a"
name_prefix = "harsha"

# Network
public_subnet_cidr  = "10.10.0.0/24"
private_subnet_cidr = "10.10.10.0/24"
psa_prefix_length   = 20

# Private VM
app_vm_machine_type = "e2-small"
vm_image            = "debian-cloud/debian-12"

# Web tier (MIG + LB)
mig_machine_type = "e2-micro"
mig_min_replicas = 2
mig_max_replicas = 4
mig_cpu_target   = 0.6

# Database (small + cheap for dev)
db_version          = "POSTGRES_15"
db_tier             = "db-f1-micro"
db_name             = "appdb"
db_user             = "appuser"
deletion_protection = false

# Who can SSH to private VMs through IAP. Example:
# iap_ssh_members = ["user:harsha@example.com"]
iap_ssh_members = []

labels = {
  owner = "harsha"
}
