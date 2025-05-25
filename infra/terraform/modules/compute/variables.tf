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

variable "env_name" {}

variable "db_user" {}
variable "db_password" {}
variable "db_name" {}
variable "db_host" {}
variable "project_id" {}
variable "db_port" {}
variable "redis_port" {}
variable "redis_host" {}
variable "pubsub_topic" {}
variable "threshold" {}
variable "region" {}
variable "project_name" {}
variable "deletion_protection" {
  type = bool
}