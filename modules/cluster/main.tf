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
  name                     = "general-purpose-cluster"
  location                 = var.location
  remove_default_node_pool = true
  initial_node_count       = 1 # For default pool, which gets removed
  master_auth {
    client_certificate_config {
      issue_client_certificate = true
      # Omit username and password to disable insecure basic auth to master
    }
  }
  workload_identity_config {
    identity_namespace = "${var.project}.svc.id.goog"
  }
}

# resource "google_container_node_pool" "pool_2gb" {
#   project            = var.project
#   name               = "pool-2gb"
#   location           = var.location
#   cluster            = google_container_cluster.general_purpose.name
#   initial_node_count = 1
#   autoscaling {
#     min_node_count = var.min_node_2gb_count
#     max_node_count = var.max_node_2gb_count
#   }
#   node_config {
#     preemptible     = true
#     machine_type    = "e2-small"
#     disk_size_gb    = 32
#     service_account = google_service_account.gke.email
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#     workload_metadata_config {
#       mode = "GKE_METADATA"
#     }
#   }
# }

# resource "google_container_node_pool" "pool_4gb" {
#   project            = var.project
#   name               = "pool-4gb"
#   location           = var.location
#   cluster            = google_container_cluster.general_purpose.name
#   initial_node_count = 1
#   autoscaling {
#     min_node_count = var.min_node_4gb_count
#     max_node_count = var.max_node_4gb_count
#   }
#   node_config {
#     preemptible     = true
#     machine_type    = "e2-medium"
#     disk_size_gb    = 32
#     service_account = google_service_account.gke.email
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#     workload_metadata_config {
#       mode = "GKE_METADATA"
#     }
#   }
# }

resource "google_container_node_pool" "pool_8gb" {
  project            = var.project
  name               = "pool-8gb"
  location           = var.location
  cluster            = google_container_cluster.general_purpose.name
  initial_node_count = 1
  autoscaling {
    min_node_count = var.min_node_8gb_count
    max_node_count = var.max_node_8gb_count
  }
  node_config {
    preemptible     = true
    machine_type    = "e2-standard-2"
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

provider "kubernetes" {
  host                   = "https://${google_container_cluster.general_purpose.endpoint}"
  token                  = var.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.general_purpose.master_auth.0.cluster_ca_certificate)
}

resource "kubernetes_cluster_role_binding" "client_cluster_admin" {
  metadata {
    annotations = {}
    labels      = {}
    name        = "client-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "client"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }
  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}
