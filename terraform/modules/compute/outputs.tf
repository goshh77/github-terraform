output "name" {
  value = google_compute_instance.this.name
}

output "internal_ip" {
  value = google_compute_instance.this.network_interface[0].network_ip
}

output "self_link" {
  value = google_compute_instance.this.self_link
}
