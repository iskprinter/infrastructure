locals {
  application_subnet_secondary_ip_range_name_for_pods     = "kubernetes-pods"
  application_subnet_secondary_ip_range_name_for_services = "kubernetes-services"
}

resource "google_compute_network" "main" {
  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
  name                     = "main"
  project                  = var.project
}

# 1.0.0.0/21 (1.0.0.0 to 1.0.7.255, 2048 total)
resource "google_compute_subnetwork" "ingress" {
  ip_cidr_range              = "1.0.0.0/21"
  ipv6_access_type           = "INTERNAL" # External IPV6 addresses are currently only allowed on the Premium tier. https://cloud.google.com/network-tiers/docs/overview#resources
  name                       = "ingress"
  network                    = google_compute_network.main.id
  private_ip_google_access   = false
  private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE" # External IPV6 addresses are currently only allowed on the Premium tier. https://cloud.google.com/network-tiers/docs/overview#resources
  project                    = var.project
  region                     = var.region
  stack_type                 = "IPV4_IPV6"
}

# + 1.0.8.0/23 (1.0.8.0 to 1.0.9.255, 512 total) for nodes
# + 1.0.10.0/23 (1.0.10.0 to 1.0.11.255, 512 total) for services
# + 1.0.12.0/22 (1.0.12.0 to 1.0.15.255, 1024 total) for pods
# = 1.0.8.0/21 (1.0.8.0 to 1.0.15.255, 2048 total)
resource "google_compute_subnetwork" "application" {
  ip_cidr_range              = "1.0.8.0/23"
  ipv6_access_type           = "INTERNAL"
  name                       = "application"
  network                    = google_compute_network.main.id
  private_ip_google_access   = true
  private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"
  project                    = var.project
  region                     = var.region
  stack_type                 = "IPV4_IPV6"
  secondary_ip_range {
    ip_cidr_range = "1.0.12.0/22"
    range_name    = local.application_subnet_secondary_ip_range_name_for_pods
  }
  secondary_ip_range {
    ip_cidr_range = "1.0.10.0/23"
    range_name    = local.application_subnet_secondary_ip_range_name_for_services
  }
}

# 1.0.16.0/21 (1.0.16.0 to 1.0.23.255, 2048 total)
resource "google_compute_subnetwork" "data" {
  ip_cidr_range              = "1.0.16.0/21"
  ipv6_access_type           = "INTERNAL"
  name                       = "data"
  network                    = google_compute_network.main.id
  private_ip_google_access   = true
  private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"
  project                    = var.project
  region                     = var.region
  stack_type                 = "IPV4_IPV6"
}

resource "google_compute_router" "main" {
  name    = "main"
  network = google_compute_network.main.id
  project = var.project
  region  = var.region
}

resource "google_compute_router_nat" "main" {
  name                               = "main"
  nat_ip_allocate_option             = "AUTO_ONLY"
  project                            = var.project
  region                             = var.region
  router                             = google_compute_router.main.name
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.application.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  subnetwork {
    name                    = google_compute_subnetwork.data.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

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

resource "google_container_cluster" "main" {
  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.gke.email
    }
  }
  cost_management_config {
    enabled = true
  }
  enable_autopilot         = true
  enable_l4_ilb_subsetting = true
  ip_allocation_policy {
    cluster_secondary_range_name  = local.application_subnet_secondary_ip_range_name_for_pods
    services_secondary_range_name = local.application_subnet_secondary_ip_range_name_for_services
    stack_type                    = "IPV4_IPV6"
  }
  location                   = var.region
  network                    = google_compute_network.main.id
  name                       = var.cluster_name
  private_ipv6_google_access = "PRIVATE_IPV6_GOOGLE_ACCESS_BIDIRECTIONAL"
  project                    = var.project
  release_channel {
    channel = var.kubernetes_release_channel
  }
  subnetwork = google_compute_subnetwork.application.name
  vertical_pod_autoscaling {
    enabled = true
  }
}
