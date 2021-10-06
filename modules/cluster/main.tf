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
      issue_client_certificate = true
      # Omit username and password to disable insecure basic auth to master
    }
  }
  workload_identity_config {
    identity_namespace = "${var.project}.svc.id.goog"
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
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
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
