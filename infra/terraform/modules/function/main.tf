resource "google_storage_bucket" "source_bucket" {
  name     = "${var.name}-bucket-${var.env_name}"
  location = var.region

  uniform_bucket_level_access = true
}

# Deploy the Cloud Function
resource "google_cloudfunctions_function" "func" {
  name        = var.name
  runtime     = var.runtime
  region      = var.region
  entry_point = var.entry_point

  source_archive_bucket = google_storage_bucket.source_bucket.name
  source_archive_object = "${var.name}-artifact-${var.env_name}.zip"

  service_account_email = var.service_account_email

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = var.pubsub_topic
  }

  vpc_connector      = var.vpc_connector
  ingress_settings   = "ALLOW_ALL"
  environment_variables = var.env_vars
}