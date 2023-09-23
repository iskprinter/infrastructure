# Image Registry

resource "google_artifact_registry_repository" "iskprinter" {
  provider      = google-beta
  project       = var.project
  repository_id = "iskprinter"
  location      = var.region
  format        = "DOCKER"
}
