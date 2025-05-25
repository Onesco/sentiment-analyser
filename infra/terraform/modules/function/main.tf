# Point at your existing bucket
data "google_storage_bucket" "source_bucket" {
  name = "worker-function-artifacts"
}

# Point at the existing object
data "google_storage_bucket_object" "source_object" {
  bucket = data.google_storage_bucket.source_bucket.name
  name   = "worker-${var.env_name}/${var.project_name}-artifact-${var.env_name}.zip"
  depends_on = [ data.google_storage_bucket.source_bucket ]
}

# Deploy the Cloud Function
resource "google_cloudfunctions_function" "func" {
  name        = var.name
  runtime     = var.runtime
  region      = var.region
  entry_point = var.entry_point

  source_archive_bucket = data.google_storage_bucket.source_bucket.name
  source_archive_object = data.google_storage_bucket_object.source_object.name

  service_account_email = var.service_account_email

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = var.pubsub_topic
  }

  vpc_connector      = var.vpc_connector
  ingress_settings   = "ALLOW_INTERNAL_ONLY"
  environment_variables = var.env_vars
  depends_on = [ var.serverless_connector ]
}