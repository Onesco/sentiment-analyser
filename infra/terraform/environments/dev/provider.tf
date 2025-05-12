provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file("../../../../credentials/sentiment-analysis-app-459419-c500eb62060c.json")
}
