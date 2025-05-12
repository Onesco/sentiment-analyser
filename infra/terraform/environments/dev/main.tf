# 1) VPC & Subnets + Firewalls
module "network" {
  source              = "../../modules/network"
  vpc_name            = "${var.project_id}-vpc"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  region              = var.region
  ssh_source_cidr     = var.ssh_source_cidr
}

# 2) Service Accounts
resource "google_service_account" "compute_sa" {
  account_id   = "compute-sa"
  display_name = "Compute VM SA"
}

resource "google_service_account" "function_sa" {
  account_id   = "function-sa"
  display_name = "Cloud Function SA"
}

# 3) IAM Bindings for Compute VM SA
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

# AI related roles
resource "google_project_iam_member" "compute_vortex_admin" {
  project = var.project_id
  role    = "roles/vortexapi.admin"
  member  = "serviceAccount:${google_service_account.compute_sa.email}"
}

resource "google_project_iam_member" "compute_language_admin" {
  project = var.project_id
  role    = "roles/language.admin"
  member  = "serviceAccount:${google_service_account.compute_sa.email}"
}

resource "google_project_iam_member" "compute_vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.compute_sa.email}"
}


# 4) IAM Bindings for Function SA
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

# 5) Pub/Sub
module "pubsub" {
  source            = "../../modules/pubsub"
  topic_name        = "${var.name}-topic-${var.env}"
  subscription_name = "${var.name}-sub--${var.env}"
}

# Redis
module "redis" {
  source          = "../../modules/redis"
  name            = "${var.name}-redis--${var.env}"
  region          = var.region
  tier            = "STANDARD_HA"
  memory_size_gb  = 2
  private_network = module.network.private_subnet_id
}

# VPC Connector (for Cloud Function)
resource "google_vpc_access_connector" "connector" {
  name          = "${var.name}-functions-connector-${var.env}"
  region        = var.region
  network       = module.network.vpc_id
  ip_cidr_range = "10.8.0.0/28"
}

# Compute VM
module "compute" {
  source                = "../../modules/compute"
  name                  = "${var.name}-vm--${var.env}"
  zone                  = var.zone
  machine_type          = "e2-medium"
  subnet_id             = module.network.public_subnet_id
  service_account_email = google_service_account.compute_sa.email
  tags                  = ["http-server", "ssh-server"]
}

# Cloud SQL
module "sql" {
  source          = "../../modules/sql"
  name            = "${var.name}-sql--${var.env}"
  region          = var.region
  private_network = module.network.private_subnet_id
}

locals {
  default = {
    DB_CONN   = module.sql.instance_connection_name
    DB_USER   = var.db_user
    DB_PASS   = module.sql.db_password
    THRESHOLD = var.sentiment_threshold
    DB_PORT   = 5432
  }
}

# Cloud Function
module "function" {
  source                = "../../modules/function"
  name                  = "${var.name}-handler-${var.env}"
  region                = var.region
  service_account_email = google_service_account.function_sa.email
  bucket_name           = var.bucket_name
  entry_point           = var.fn_entry_point
  pubsub_topic          = module.pubsub.topic_id
  vpc_connector         = google_vpc_access_connector.connector.name
  env_vars              = local.default
}

# Outputs
output "vm_ip" {
  value = module.compute.instance_ip
}

output "pubsub_topic" {
  value = module.pubsub.topic_id
}

output "redis_endpoint" {
  value = "${module.redis.host}:${module.redis.port}"
}

output "sql_connection" {
  value = module.sql.instance_connection_name
}
