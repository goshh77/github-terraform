output "network_id" {
  value = google_compute_network.vpc.id
}

output "network_name" {
  value = google_compute_network.vpc.name
}

output "network_self_link" {
  value = google_compute_network.vpc.self_link
}

output "public_subnet_id" {
  value = google_compute_subnetwork.public.id
}

output "private_subnet_id" {
  value = google_compute_subnetwork.private.id
}

output "private_subnet_self_link" {
  value = google_compute_subnetwork.private.self_link
}

output "psa_connection_id" {
  value = google_service_networking_connection.psa.id
}
