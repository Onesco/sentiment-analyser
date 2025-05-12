resource "google_compute_instance" "vm" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.tags

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
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

  metadata = {
    startup-script = file("../../scripts/startup.sh")
  }
}
