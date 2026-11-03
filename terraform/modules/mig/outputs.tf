output "instance_group" {
  description = "Instance group URL, used as the LB backend."
  value       = google_compute_region_instance_group_manager.web.instance_group
}

output "health_check_id" {
  value = google_compute_health_check.web.id
}

output "instance_template" {
  value = google_compute_instance_template.web.self_link_unique
}
