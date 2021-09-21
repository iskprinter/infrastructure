resource "google_service_account" "gke" {
  project      = var.project
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
}

resource "google_container_cluster" "general_purpose" {
  project                  = var.project
  name                     = "general-purpose-cluster"
  location                 = var.location
  remove_default_node_pool = true
  initial_node_count       = 1 # For default pool, which gets removed
  master_auth {
    client_certificate_config {
      # Disables basic auth to master
      issue_client_certificate = true
    }
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  project  = var.project
  name     = "node-pool-of-${google_container_cluster.general_purpose.name}"
  location = var.location
  cluster  = google_container_cluster.general_purpose.name
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  node_config {
    preemptible     = true
    machine_type    = "e2-medium"
    disk_size_gb    = 32
    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

}
