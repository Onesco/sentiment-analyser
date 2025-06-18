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

# # Deploy the Cloud Function
resource "google_cloudfunctions2_function" "func" {
  name        = var.name
  location    = var.region
  description = "Cloud Function 2nd Gen"

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    source {
      storage_source {
        bucket = data.google_storage_bucket.source_bucket.name
        object = data.google_storage_bucket_object.name
      }
    }
    environment_variables = var.env_vars
  }

  service_config {
    service_account_email = var.service_account_email
    vpc_connector         = var.vpc_connector
    ingress_settings      = "INGRESS_SETTINGS_INTERNAL_ONLY"
    max_instance_count    = 3
    timeout_seconds       = 60
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = var.pubsub_topic
    retry_policy   = "RETRY_POLICY_RETRY"
  }

  depends_on = [var.serverless_connector]
}