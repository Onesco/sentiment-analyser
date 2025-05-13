terraform {
  backend "gcs" {
    bucket  = "${var.name}-backend-${var.env_name}"
    prefix  = "terraform/state"
  }
}