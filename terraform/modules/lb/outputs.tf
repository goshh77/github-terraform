output "ip_address" {
  value = google_compute_global_address.lb.address
}

output "backend_service_id" {
  value = google_compute_backend_service.web.id
}
