terraform {
  required_version = ">= 1.0"
  backend "gcs" {
    bucket  = "driven-realm-460409-n1-terraform-state-bucket"
    prefix  = "teraform/state/dev"
  }
}

