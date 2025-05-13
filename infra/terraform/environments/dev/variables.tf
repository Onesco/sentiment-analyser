variable "project_id" {
  type    = string
  default = "sentiment-analysis-app-459419"
}
variable "region" { default = "us-central1" }
variable "zone" { default = "us-central1-a" }
variable "db_user" {}
variable "db_name" { default = "sentiment-analyser-db-dev" }
variable "pubsub_topic" { default = "summarization-completed" }
variable "public_cidr" { default = "10.0.1.0/24" }
variable "private_cidr" { default = "10.0.2.0/24" }
variable "instance_name" { default = "nest-sql-dev" }
variable "compute_name" { default = "nest-api-dev" }
variable "machine_type" { default = "e2-small" }
variable "docker_image" { default = "gcr.io/sentiment-analysis-app-459419/sentiment-analyser-app-dev:latest" }


variable "fn_runtime" { default = "nodejs20" }
variable "fn_entry_point" { default = "pubSubHandler" }

variable "fn_memory_mb" { default = 256 }
variable "fn_timeout" { default = 60 }
variable "name" {
  default = "setiment-analyser"
}
variable "env_name" {
  default = "dev"
}
variable "ssh_source_cidr" {}
variable "sentiment_threshold" {
  default = 0
  type    = number
}
variable "credentails" {
  type = string
}