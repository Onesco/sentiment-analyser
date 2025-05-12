output "host" {
  description = "Redis instance host IP"
  value       = google_redis_instance.this.host
}

output "port" {
  description = "Redis instance port"
  value       = google_redis_instance.this.port
}
