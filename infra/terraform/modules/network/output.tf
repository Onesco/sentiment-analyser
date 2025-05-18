output "public_subnet_id" {
  value = google_compute_subnetwork.public.id
}
output "vpc_self_link" {
  value = google_compute_network.vpc.self_link
}

output "vpc_access_connector" {
  value = google_vpc_access_connector.connector.id
}