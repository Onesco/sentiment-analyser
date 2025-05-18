
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
    "pubsub.googleapis.com",
    "vpcaccess.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}

# Service Accounts
resource "google_service_account" "compute_sa" {
  account_id   = "compute-sa"
  display_name = "Compute VM SA"
}
resource "google_service_account" "function_sa" {
  account_id   = "function-sa"
  display_name = "Cloud Function SA"
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

# IAM Bindings for Function SA
resource "google_project_iam_member" "function_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}
resource "google_project_iam_member" "function_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "function_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_service_account_iam_member" "terraform_can_act_as_function_sa" {
  service_account_id = google_service_account.function_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:terraform-sa@${var.project_id}.iam.gserviceaccount.com"
}

#  VPC & Subnet + Firewalls
module "network" {
  source              = "../../modules/network"
  vpc_name            = "${var.name}-vpc"
  public_subnet_cidr  = var.public_cidr
  region              = var.region
  ssh_source_cidr     = var.ssh_source_cidr
  private_subnet_cidr = var.private_cidr
  env_name            = var.env_name
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

# Redis
module "redis" {
  source          = "../../modules/redis"
  name            = "${var.name}-redis--${var.env_name}"
  region          = var.region
  tier            = "BASIC"
  memory_size_gb  = 2
  private_network = module.network.vpc_self_link
}

# Pub/Sub
module "pubsub" {
  source            = "../../modules/pubsub"
  topic_name        = "${var.name}-topic-${var.env_name}"
  subscription_name = "${var.name}-sub--${var.env_name}"
}

locals {
  default = {
    DB_HOST          = module.sql.db_host
    DB_USERNAME      = module.sql.db_username
    DB_PASSWORD      = module.sql.db_password
    THRESHOLD        = var.sentiment_threshold
    DB_PORT          = var.db_port
    SERVER_BASE_URL  = "http://${module.compute.instance_internal_ip}:${var.server_port}"
    DB_NAME          = module.sql.db_name
  }
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
  db_host               = module.sql.db_host
  db_name               = module.sql.db_name
  db_password           = module.sql.db_password
  db_user               = module.sql.db_username
  env_name              = var.env_name
  project_id            = var.project_id
  pubsub_topic          = module.pubsub.topic_name
  redis_host            = module.redis.redis_host
  redis_port            = module.redis.redis_port
  db_port               = var.db_port
  threshold             = var.sentiment_threshold
  region                = var.region
  project_name          = var.name
}

# # Cloud Function
module "function" {
  source                = "../../modules/function"
  name                  = "${var.name}-func-${var.env_name}"
  region                = var.region
  service_account_email = google_service_account.function_sa.email
  env_name              = var.env_name
  entry_point           = var.fn_entry_point
  pubsub_topic          = module.pubsub.topic_id
  vpc_connector         = module.network.vpc_access_connector
  env_vars              = local.default
  project_name           = var.name
}
