variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default = "sentiment-analysis-app-459419"
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
  type    = string
  default = "sentiment-analyser"
}

variable "public_cidr" { 
  default = "10.0.1.0/24" 
}

variable "private_cidr" { 
  default = "10.0.2.0/28" 
}

variable "ssh_source_cidr" {}

variable "env_name" {
  default = "dev"
}

variable "machine_type" {
  default = "e2-medium"
}

variable "fn_entry_point" {
  default = "pubSubHandler"
}

variable "sentiment_threshold" {
  default = 0
  type    = number
}

variable "db_port" {
  default = 5432
}

variable "server_port" {
  default = 3000
}