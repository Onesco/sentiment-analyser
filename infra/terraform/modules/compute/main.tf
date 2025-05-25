resource "google_compute_instance" "vm" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.tags

  boot_disk {
    initialize_params {
      image = var.image_name
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    access_config {}
  }

  service_account {
    email = var.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  deletion_protection = var.deletion_protection

  metadata_startup_script = templatefile("../../scripts/startup.sh", {
    DOCKER_IMAGE    = "${var.region}-docker.pkg.dev/${var.project_id}/${var.project_name}:latest"
    DB_USERNAME    = var.db_user
    DB_PASSWORD = var.db_password
    CONTAINER_NAME  = "${var.region}-docker.pkg.dev/${var.project_id}/${var.project_name}:latest"
    DB_HOST = var.db_host
    DB_NAME = var.db_name
    DB_PORT = var.db_port
    TTL = 3600
    PUBSUB_TOPIC = var.pubsub_topic
    REDIS_HOST = var.redis_host
    REDIS_PORT = var.redis_port
    THRESHOLD = var.threshold
    GOOGLE_PROJECT_ID = var.project_id
  })
}