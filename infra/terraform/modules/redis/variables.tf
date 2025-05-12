variable "name" {
  type        = string
  description = "Name of the Redis instance"
}

variable "region" {
  type        = string
  description = "Region where Redis will be provisioned"
}

variable "tier" {
  type        = string
  description = "Redis tier (e.g. BASIC, STANDARD_HA)"
  default     = "BASIC"
}

variable "memory_size_gb" {
  type        = number
  description = "Memory size in GB"
  default     = 1
}

variable "private_network" {
  type        = string
  description = "The VPC network self-link for private IP connectivity"
}
