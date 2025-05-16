
# setting up terraform state file bucket
resource "google_storage_bucket" "terraform_state" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  uniform_bucket_level_access = true
}


# enabled required  API
resource "google_project_service" "required" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "pubsub.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "language.googleapis.com",
    "artifactregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}

# Service Accounts
resource "google_service_account" "compute_sa" {
  account_id   = "compute-sa"
  display_name = "Compute VM SA"
}

# IAM Bindings for Compute VM SA
resource "google_project_iam_member" "compute_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.compute_sa.email}"
}

resource "google_project_iam_member" "compute_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.compute_sa.email}"
}

resource "google_project_iam_member" "compute_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.compute_sa.email}"
}

resource "google_project_iam_member" "compute_redis" {
  project = var.project_id
  role    = "roles/redis.editor"
  member  = "serviceAccount:${google_service_account.compute_sa.email}"
}

resource "google_project_iam_member" "compute_artifactregistry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.compute_sa.email}"
}

resource "google_service_account_iam_member" "compute_sa_user_access" {
  service_account_id = google_service_account.compute_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:terraform-sa@${var.project_id}.iam.gserviceaccount.com"
}


# # Compute VM
module "compute" {
  source                = "../../modules/compute"
  name                  = "${var.name}-vm-${var.env_name}"
  zone                  = var.zone
  machine_type          = var.machine_type
  subnet_id             = module.network.public_subnet_id
  service_account_email = google_service_account.compute_sa.email
  tags                  = ["http-server", "ssh-server"]
}


#  VPC & Subnet + Firewalls
module "network" {
  source              = "../../modules/network"
  vpc_name            = "${var.name}-vpc"
  public_subnet_cidr  = var.public_cidr
  region              = var.region
  ssh_source_cidr     = var.ssh_source_cidr
}


# Cloud SQL
module "sql" {
  source          = "../../modules/sql"
  name            = "${var.name}-sql-${var.env_name}"
  region          = var.region
  db_user         = "${var.name}-db-user-${var.env_name}"
  db_name         = "${var.name}-db-${var.env_name}"
  private_network = module.network.vpc_self_link
}

