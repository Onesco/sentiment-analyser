output "function_name" {
  value = google_cloudfunctions2_function.func.name
}

output "trigger_topic" {
  value = var.pubsub_topic
}