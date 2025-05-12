output "function_name" {
  value = google_cloudfunctions_function.func.name
}

output "trigger_topic" {
  value = var.pubsub_topic
}