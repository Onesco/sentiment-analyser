output "topic_id" {
  description = "ID of the Pub/Sub topic"
  value       = google_pubsub_topic.this.id
}
output "topic_name" {
  description = "ID of the Pub/Sub topic"
  value       = google_pubsub_topic.this.name
}
output "subscription_id" {
  description = "ID of the Pub/Sub subscription"
  value       = google_pubsub_subscription.this.id
}
