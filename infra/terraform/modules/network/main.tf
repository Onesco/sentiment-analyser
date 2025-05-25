resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_route" "default_internet" {
  name             = "${var.vpc_name}-default-route"
  network          = google_compute_network.vpc.self_link
  dest_range       = "0.0.0.0/0"
  priority         = 1000
  next_hop_gateway = "default-internet-gateway"
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.vpc_name}-public"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  depends_on = [ google_compute_network.vpc ]
}
resource "google_compute_firewall" "allow_http" {
  name    = "${var.vpc_name}-allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
  depends_on = [ google_compute_network.vpc ]
}


resource "google_compute_firewall" "allow_redis" {
  name    = "${var.vpc_name}-allow-redis"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  direction     = "INGRESS"
  source_ranges = [var.public_subnet_cidr]
  depends_on = [ google_compute_network.vpc ]
}


resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["ssh-server"]
  depends_on = [ google_compute_network.vpc ]
}

