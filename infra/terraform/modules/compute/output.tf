output "instance_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "instance_internal_ip" {
  value = google_compute_instance.vm.network_interface[0].network_ip
}

output "instance_public_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}
