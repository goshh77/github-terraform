variable "project_id" {
  type = string
}

variable "service_accounts" {
  description = "Map of service account id (6-30 chars) => display name and project roles."
  type        = map(object({
    display_name = string
    roles        = list(string)
  }))
}
