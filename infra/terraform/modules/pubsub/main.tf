# Create the topic
resource "google_pubsub_topic" "this" {
  name = var.topic_name
}

# Create a subscription on that topic
resource "google_pubsub_subscription" "this" {
  name  = var.subscription_name
  topic = google_pubsub_topic.this.id

  ack_deadline_seconds = var.ack_deadline_seconds
  depends_on = [ google_pubsub_topic.this ]
}
