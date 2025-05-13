# 0) Enable required Google APIs
resource "google_project_service" "cloudresourcemanager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}


resource "google_project_service" "pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"
}
resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"
}
resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
}
resource "google_project_service" "redis" {
  project = var.project_id
  service = "redis.googleapis.com"
}

resource "google_project_service" "vpcaccess" {
  project = var.project_id
  service = "vpcaccess.googleapis.com"
}
resource "google_project_service" "language" {
  project = var.project_id
  service = "language.googleapis.com"
}
resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "aiplatform" {
  project = var.project_id
  service = "aiplatform.googleapis.com"
}

resource "google_project_service" "servicenetworking" {
  project            = var.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudfunctions" {
  project            = var.project_id
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}


# 1) VPC & Subnets + Firewalls
module "network" {
  source              = "../../modules/network"
  vpc_name            = "${var.project_id}-vpc"
  public_subnet_cidr  = var.public_cidr
  private_subnet_cidr = var.private_cidr
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

resource "google_project_iam_member" "compute_artifactregistry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
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
resource "google_project_iam_member" "function_language_user" {
  project = var.project_id
  role    = "roles/cloudlanguage.user"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

# 5) Pub/Sub
module "pubsub" {
  source            = "../../modules/pubsub"
  topic_name        = "${var.name}-topic-${var.env_name}"
  subscription_name = "${var.name}-sub--${var.env_name}"
}

# Redis
module "redis" {
  source          = "../../modules/redis"
  name            = "${var.name}-redis--${var.env_name}"
  region          = var.region
  tier            = "STANDARD_HA"
  memory_size_gb  = 2
  private_network = module.network.private_subnet_id
}

# VPC Connector (for Cloud Function)
resource "google_vpc_access_connector" "connector" {
  name          = "${var.name}-fn-${var.env_name}"
  region        = var.region
  network       = module.network.vpc_id
  ip_cidr_range = "10.8.0.0/28"
  max_throughput = 300
}

# Compute VM
module "compute" {
  source                = "../../modules/compute"
  name                  = "${var.name}-vm--${var.env_name}"
  zone                  = var.zone
  machine_type          = "e2-medium"
  subnet_id             = module.network.public_subnet_id
  service_account_email = google_service_account.compute_sa.email
  tags                  = ["http-server", "ssh-server"]
}

# Cloud SQL
module "sql" {
  source          = "../../modules/sql"
  name            = "${var.name}-sql--${var.env_name}"
  region          = var.region
  private_network = module.network.vpc_id
  db_user         = var.db_user
  db_name         = var.db_name
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
  name                  = "${var.name}-handler-${var.env_name}"
  region                = var.region
  service_account_email = google_service_account.function_sa.email
  env                   = var.env_name
  entry_point           = var.fn_entry_point
  pubsub_topic          = module.pubsub.topic_id
  vpc_connector         = google_vpc_access_connector.connector.name
  env_vars              = local.default
}


# Grant your Terraform runner the Service Account User role on the Compute SA
resource "google_service_account_iam_member" "compute_sa_user" {
  service_account_id = google_service_account.compute_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:terraform-sa@${var.project_id}.iam.gserviceaccount.com"
}

# And likewise for the Function SA
resource "google_service_account_iam_member" "function_sa_user" {
  service_account_id = google_service_account.function_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:terraform-sa@${var.project_id}.iam.gserviceaccount.com"
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
