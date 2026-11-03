############################
# Project / location
############################
variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Primary region for all regional resources."
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "Default zone for zonal resources (e.g. the private VM)."
  type        = string
  default     = "asia-south1-a"
}

variable "environment" {
  description = "Environment name (dev, stage, prod). Used in resource names and labels."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,10}$", var.environment))
    error_message = "environment must be lowercase letters, digits or hyphens (2-11 chars)."
  }
}

variable "name_prefix" {
  description = "Short prefix applied to every resource name."
  type        = string
  default     = "harsha"
}

variable "labels" {
  description = "Extra labels merged into every resource."
  type        = map(string)
  default     = {}
}

############################
# Network
############################
variable "public_subnet_cidr" {
  description = "CIDR for the public subnet (only for resources that genuinely need an external IP)."
  type        = string
  default     = "10.10.0.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet (VMs, MIG). No external IPs; egress via Cloud NAT."
  type        = string
  default     = "10.10.10.0/24"
}

variable "psa_prefix_length" {
  description = "Prefix length reserved for Private Service Access (Cloud SQL private IP)."
  type        = number
  default     = 20
}

############################
# Private VM
############################
variable "app_vm_machine_type" {
  description = "Machine type for the private application VM."
  type        = string
  default     = "e2-small"
}

variable "vm_image" {
  description = "Boot image used by the VM and the MIG template."
  type        = string
  default     = "debian-cloud/debian-12"
}

############################
# Managed instance group / LB
############################
variable "mig_machine_type" {
  description = "Machine type for MIG web instances."
  type        = string
  default     = "e2-micro"
}

variable "mig_min_replicas" {
  description = "Autoscaler minimum instances."
  type        = number
  default     = 2
}

variable "mig_max_replicas" {
  description = "Autoscaler maximum instances."
  type        = number
  default     = 4
}

variable "mig_cpu_target" {
  description = "Target CPU utilisation (0-1) for the autoscaler."
  type        = number
  default     = 0.6
}

############################
# Database
############################
variable "db_version" {
  description = "Cloud SQL engine version."
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "Cloud SQL machine tier. db-f1-micro is the smallest/cheapest."
  type        = string
  default     = "db-f1-micro"
}

variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Application database user."
  type        = string
  default     = "appuser"
}

variable "deletion_protection" {
  description = "Protect stateful resources (Cloud SQL) from deletion. Set true for prod."
  type        = bool
  default     = false
}

############################
# Access
############################
variable "iap_ssh_members" {
  description = "Principals allowed to SSH to private VMs through IAP, e.g. [\"user:you@example.com\"]."
  type        = list(string)
  default     = []
}
