variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "tier" {
  type    = string
  default = "db-f1-micro"
}

variable "database_version" {
  type    = string
  default = "POSTGRES_14"
}

variable "private_network" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_name" {
  type = string
}