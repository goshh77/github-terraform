variable "name" {
  type = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-small"
}

variable "image" {
  type    = string
  default = "debian-cloud/debian-12"
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "subnetwork_id" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "labels" {
  type    = map(string)
  default = {}
}
