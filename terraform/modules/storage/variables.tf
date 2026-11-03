variable "name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "location" {
  type = string
}

variable "force_destroy" {
  description = "Allow terraform destroy to delete a non-empty bucket."
  type        = bool
  default     = false
}

variable "object_admins" {
  description = "Static key => IAM member granted objectAdmin."
  type        = map(string)
  default     = {}
}

variable "labels" {
  type    = map(string)
  default = {}
}
