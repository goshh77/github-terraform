output "vpc_name" {
  description = "VPC network name."
  value       = module.network.network_name
}

output "private_subnet" {
  description = "Private subnet self link."
  value       = module.network.private_subnet_self_link
}

output "load_balancer_ip" {
  description = "Public IP of the HTTP load balancer."
  value       = module.lb.ip_address
}

output "load_balancer_url" {
  description = "Open this in a browser once the MIG instances are healthy (takes a few minutes)."
  value       = "http://${module.lb.ip_address}"
}

output "app_vm_name" {
  description = "Private application VM."
  value       = module.app_vm.name
}

output "app_vm_ssh_command" {
  description = "SSH to the private VM through IAP (no public IP needed)."
  value       = "gcloud compute ssh ${module.app_vm.name} --zone ${var.zone} --tunnel-through-iap --project ${var.project_id}"
}

output "db_instance_connection_name" {
  description = "Cloud SQL connection name (for the Cloud SQL Auth Proxy / connectors)."
  value       = module.database.connection_name
}

output "db_private_ip" {
  description = "Private IP of the Cloud SQL instance."
  value       = module.database.private_ip
}

output "db_password_secret" {
  description = "Secret Manager secret holding the DB password."
  value       = module.database.password_secret_id
}

output "app_bucket" {
  description = "Application data bucket."
  value       = module.app_bucket.name
}

output "service_accounts" {
  description = "Workload service accounts created by this stack."
  value       = module.iam.emails
}
