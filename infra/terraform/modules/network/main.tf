resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.vpc_name}-public"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

#Private access connect (PAC)
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.vpc_name}-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
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
}


# 1) Serverless VPC Access connector
resource "google_vpc_access_connector" "connector" {
  name           = "sa-vpc-ac-${var.env_name}"
  network        = var.vpc_name
  region         = var.region
  ip_cidr_range  = var.private_subnet_cidr
  max_instances = 3
  min_instances = 2
}