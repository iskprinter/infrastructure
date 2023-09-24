# Image Registry

resource "google_artifact_registry_repository" "iskprinter" {
  project       = var.project
  repository_id = "iskprinter"
  location      = var.region
  format        = "DOCKER"
}
