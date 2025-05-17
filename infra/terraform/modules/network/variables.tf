variable "vpc_name" {
  type        = string
  description = "Name for the VPC"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR range for the public subnet"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR range for the public subnet"
}

variable "region" {
  type        = string
  description = "Region for subnets"
}

variable "ssh_source_cidr" {
  type        = string
  description = "Allowed source CIDR for SSH"
}
variable "env_name" {
  default = "dev"
}
