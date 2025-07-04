variable "name" {
  type = string
}

variable "runtime" {
  type    = string
  default = "nodejs20"
}

variable "region" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "entry_point" {
  type = string
}

variable "pubsub_topic" {
  type = string
}

variable "vpc_connector" {
  type = string
}

variable "env_vars" {
  type = map(string)
}

variable "env_name" {
  type = string
}

variable "project_name" {}
variable "serverless_connector" {}