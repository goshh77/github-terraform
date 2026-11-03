variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "image" {
  type    = string
  default = "debian-cloud/debian-12"
}

variable "subnetwork_id" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "min_replicas" {
  type    = number
  default = 2
}

variable "max_replicas" {
  type    = number
  default = 4

  validation {
    condition     = var.max_replicas >= 1
    error_message = "max_replicas must be at least 1."
  }
}

variable "cpu_target" {
  type    = number
  default = 0.6
}

variable "labels" {
  type    = map(string)
  default = {}
}
