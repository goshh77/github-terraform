variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  description = "Name prefix for network resources."
  type        = string
}

variable "public_subnet_cidr" {
  type = string
}

variable "private_subnet_cidr" {
  type = string
}

variable "psa_prefix_length" {
  description = "Size of the range reserved for Google managed services (Cloud SQL)."
  type        = number
  default     = 20
}
