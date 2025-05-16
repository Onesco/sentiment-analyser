# variable "region" { default = "us-central1" }


# variable "pubsub_topic" { default = "summarization-completed" }

# variable "instance_name" { default = "nest-sql-dev" }
# variable "compute_name" { default = "nest-api-dev" }
# variable "machine_type" { default = "e2-small" }
# variable "docker_image" { default = "gcr.io/sentiment-analysis-app-459419/sentiment-analyser-app-dev:latest" }


# variable "fn_runtime" { default = "nodejs20" }
# variable "fn_entry_point" { default = "pubSubHandler" }

# variable "fn_memory_mb" { default = 256 }
# variable "fn_timeout" { default = 60 }
# variable "name" {
#   default = "setiment-analyser"
# }


# variable "sentiment_threshold" {
#   default = 0
#   type    = number
# }
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
  default = "setiment-analyser"
}

variable "public_cidr" { 
  default = "10.0.1.0/24" 
}

variable "ssh_source_cidr" {}

variable "env_name" {
  default = "dev"
}

variable "machine_type" {
  default = "e2-medium"
}