
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
    "vpcaccess.googleapis.com",
    "cloudbuild.googleapis.com",
    "compute.googleapis.com"
  ])
  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = true
  depends_on                 = [google_storage_bucket.terraform_state]
}

# Service Accounts
resource "google_service_account" "compute_sa" {
  account_id   = "compute-sa"
  display_name = "Compute VM SA"
  depends_on   = [google_project_service.required]

  lifecycle {
    prevent_destroy = false
  }
}
resource "google_service_account" "function_sa" {
  account_id   = "function-sa"
  display_name = "Cloud Function SA"
  depends_on   = [google_project_service.required]

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_service_account" "datadog_sa" {
  account_id   = "datadog-sa"
  display_name = "Datadog SA"
  depends_on   = [google_project_service.required]

  lifecycle {
    prevent_destroy = false
  }
}

# IAM Bindings for Compute VM SA
resource "google_project_iam_member" "compute_vertexai_user" {
  project    = var.project_id
  role       = "roles/aiplatform.user"
  member     = "serviceAccount:${google_service_account.compute_sa.email}"
  depends_on = [google_service_account.compute_sa]
  lifecycle {
    prevent_destroy = false
  }
}
resource "google_project_iam_member" "compute_pubsub" {
  project    = var.project_id
  role       = "roles/pubsub.publisher"
  member     = "serviceAccount:${google_service_account.compute_sa.email}"
  depends_on = [google_service_account.compute_sa]
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_project_iam_member" "compute_storage" {
  project    = var.project_id
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${google_service_account.compute_sa.email}"
  depends_on = [google_service_account.compute_sa]
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_project_iam_member" "compute_sql" {
  project    = var.project_id
  role       = "roles/cloudsql.client"
  member     = "serviceAccount:${google_service_account.compute_sa.email}"
  depends_on = [google_service_account.compute_sa]
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_project_iam_member" "compute_redis" {
  project    = var.project_id
  role       = "roles/redis.editor"
  member     = "serviceAccount:${google_service_account.compute_sa.email}"
  depends_on = [google_service_account.compute_sa]
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_project_iam_member" "compute_artifactregistry_reader" {
  project    = var.project_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.compute_sa.email}"
  depends_on = [google_service_account.compute_sa]
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_service_account_iam_member" "compute_sa_user_access" {
  depends_on         = [google_service_account.compute_sa]
  service_account_id = google_service_account.compute_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:terraform-sa@${var.project_id}.iam.gserviceaccount.com"
  lifecycle {
    prevent_destroy = false
  }
}

# IAM Bindings for Function SA
resource "google_project_iam_member" "function_pubsub" {
  project    = var.project_id
  role       = "roles/pubsub.subscriber"
  member     = "serviceAccount:${google_service_account.function_sa.email}"
  depends_on = [google_service_account.function_sa]
  lifecycle {
    prevent_destroy = false
  }
}
resource "google_project_iam_member" "function_sql" {
  project    = var.project_id
  role       = "roles/cloudsql.client"
  member     = "serviceAccount:${google_service_account.function_sa.email}"
  depends_on = [google_service_account.function_sa]
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_project_iam_member" "function_cloudsql_client" {
  project    = var.project_id
  role       = "roles/cloudsql.client"
  member     = "serviceAccount:${google_service_account.function_sa.email}"
  depends_on = [google_service_account.function_sa]
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_service_account_iam_member" "terraform_can_act_as_function_sa" {
  depends_on         = [google_service_account.function_sa]
  service_account_id = google_service_account.function_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:terraform-sa@${var.project_id}.iam.gserviceaccount.com"
  lifecycle {
    prevent_destroy = false
  }
}

# IAM Bindings for Datadog SA
resource "google_project_iam_member" "datadog_sa_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.datadog_sa.email}"
  depends_on = [google_service_account.compute_sa]
}


#Private access connect (PAC)
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.name}-vpc-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = module.network.vpc_self_link
  depends_on    = [module.network.vpc_self_link]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.network.vpc_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on = [ google_compute_global_address.private_ip_address ]
}

# 1) Serverless VPC Access connector
resource "google_vpc_access_connector" "connector" {
  name          = "sa-vpc-ac-${var.env_name}"
  network       = module.network.vpc_self_link
  region        = var.region
  ip_cidr_range = var.private_cidr
  max_instances = 3
  min_instances = 2
}


#  VPC & Subnet + Firewalls
module "network" {
  source             = "../../modules/network"
  vpc_name           = "${var.name}-vpc"
  public_subnet_cidr = var.public_cidr
  region             = var.region
  ssh_source_cidr    = var.ssh_source_cidr
  env_name           = var.env_name
  depends_on         = [google_project_service.required]
}


# Cloud SQL
module "sql" {
  source              = "../../modules/sql"
  name                = "${var.name}-sql-${var.env_name}"
  region              = var.region
  db_user             = "${var.name}-db-user-${var.env_name}"
  db_name             = "${var.name}-db-${var.env_name}"
  private_network     = module.network.vpc_self_link
  deletion_protection = false
  private_vpc_connection = google_service_networking_connection.private_vpc_connection

  depends_on = [google_project_service.required]
}

# Redis
module "redis" {
  source          = "../../modules/redis"
  name            = "${var.name}-redis-${var.env_name}"
  region          = var.region
  tier            = "BASIC"
  memory_size_gb  = 2
  private_network = module.network.vpc_self_link
  private_vpc_connection = google_service_networking_connection.private_vpc_connection
  
  depends_on      = [google_project_service.required]
}

# Pub/Sub
module "pubsub" {
  source            = "../../modules/pubsub"
  topic_name        = "${var.name}-topic-${var.env_name}"
  subscription_name = "${var.name}-sub--${var.env_name}"

  depends_on = [google_project_service.required]
}

locals {
  default = {
    DB_HOST         = module.sql.db_host
    DB_USERNAME     = module.sql.db_username
    DB_PASSWORD     = module.sql.db_password
    THRESHOLD       = var.sentiment_threshold
    DB_PORT         = var.db_port
    SERVER_BASE_URL = "http://${module.compute.instance_internal_ip}:${var.server_port}"
    DB_NAME         = module.sql.db_name
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
  deletion_protection   = false

  depends_on = [google_project_service.required]
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
  vpc_connector         = google_vpc_access_connector.connector.id
  env_vars              = local.default
  project_name          = var.name
  serverless_connector  = google_vpc_access_connector.connector

  depends_on = [google_project_service.required]
}


output "application_public_ip" {
  value = module.compute.instance_public_ip
}
