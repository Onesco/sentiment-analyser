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
    scopes = []
  }
  metadata_startup_script = templatefile("../../scripts/startup.sh", {
    DOCKER_IMAGE    = "gcr.io/${var.project_id}/${var.name}-app:${var.env_name}"
    DB_USERNAME    = var.db_user
    DB_PASSWORD = var.db_password
    CONTAINER_NAME  = "${var.name}-app:${var.env_name}"
    DB_HOST = var.db_host
    DB_NAME = var.db_name
    DB_PORT = var.db_port
    TTL = 3600
    PUBSUB_TOPIC = var.pubsub_topic
    REDIS_HOST = var.redis_host
    REDIS_PORT = var.redis_port
    THRESHOLD = var.threshold
  })
}
