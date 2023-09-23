resource "google_service_account" "gke" {
  project      = var.project
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
}

resource "google_project_iam_member" "gke_artifact_registry_reader_binding" {
  project = var.project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke.email}"
}

resource "google_container_cluster" "general_purpose" {
  project                  = var.project
  name                     = var.cluster_name
  location                 = var.location
  remove_default_node_pool = true
  initial_node_count       = 1 # For default pool, which gets removed
  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }
}

resource "google_container_node_pool" "pool_e2-highmem-2" {
  project            = var.project
  name               = "pool-${var.machine_type}"
  location           = var.location
  cluster            = var.cluster_name
  initial_node_count = 2
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  node_config {
    preemptible     = true
    machine_type    = var.machine_type
    disk_size_gb    = 32
    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
