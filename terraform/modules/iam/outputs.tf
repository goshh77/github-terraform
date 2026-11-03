output "emails" {
  description = "Service account id => email."
  value       = { for k, sa in google_service_account.this : k => sa.email }
}
