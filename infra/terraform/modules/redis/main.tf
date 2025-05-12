resource "google_redis_instance" "this" {
  name           = var.name
  region         = var.region
  tier           = var.tier
  memory_size_gb = var.memory_size_gb

  redis_configs = {
  }

  authorized_network = var.private_network
}
