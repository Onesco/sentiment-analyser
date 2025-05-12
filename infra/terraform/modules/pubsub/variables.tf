variable "topic_name" {
  type        = string
  description = "Name of the Pub/Sub topic"
}

variable "subscription_name" {
  type        = string
  description = "Name of the Pub/Sub subscription"
}

variable "ack_deadline_seconds" {
  type        = number
  description = "Acknowledgement deadline in seconds"
  default     = 60
}
