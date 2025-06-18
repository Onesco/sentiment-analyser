variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region (e.g., us-central1)"
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "The name of the GCS bucket to create"
  type        = string
}

variable "zone" {
  default = "us-central1-a"
  type    = string
}

variable "name" {
  type = string
}

variable "public_cidr" {
}

variable "private_cidr" {
}

variable "ssh_source_cidr" {}

variable "env_name" {
}

variable "machine_type" {

}

variable "fn_entry_point" {
}

variable "sentiment_threshold" {
  type = number
}

variable "db_port" {
}

variable "server_port" {
}
variable "DD_API_KEY" {
}
variable "DD_SITE" {
}