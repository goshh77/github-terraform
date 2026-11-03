variable "name" {
  type = string
}

variable "instance_group" {
  description = "Instance group URL from the MIG module."
  type        = string
}

variable "health_check_id" {
  type = string
}
