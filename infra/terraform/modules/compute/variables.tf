variable "name" {
  type = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "subnet_id" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "tags" {
  type = list(string)
}
variable "image_name" {
  default = "debian-cloud/debian-11"
}