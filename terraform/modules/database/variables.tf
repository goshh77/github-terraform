variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "network_id" {
  description = "VPC with Private Service Access already configured."
  type        = string
}

variable "database_version" {
  type    = string
  default = "POSTGRES_15"
}

variable "tier" {
  type    = string
  default = "db-f1-micro"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "secret_accessors" {
  description = "Static key => IAM member allowed to read the DB password secret."
  type        = map(string)
  default     = {}
}

variable "labels" {
  type    = map(string)
  default = {}
}
