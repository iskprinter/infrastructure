resource "google_dns_managed_zone" "iskprinter" {
  project     = var.project
  name        = "iskprinter-com"
  dns_name    = "iskprinter.com."
  description = "Managed zone for iskprinter hosts"
}

resource "google_service_account" "external_dns" {
  project      = var.project
  account_id   = "external-dns"
  display_name = "External DNS Service Account"
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    namespace = kubernetes_namespace.external_dns.metadata[0].name
    name      = "external-dns"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.external_dns.email
    }
  }
}

resource "google_service_account_iam_member" "service_account_iam_workload_identity_user_binding" {
  service_account_id = google_service_account.external_dns.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${kubernetes_service_account.external_dns.metadata[0].namespace}/${kubernetes_service_account.external_dns.metadata[0].name}]"
}

resource "google_project_iam_member" "service_account_dns_record_sets_binding" {
  project = var.project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.external_dns.email}"
}

resource "kubernetes_cluster_role" "external_dns" {
  metadata {
    name = "external-dns"
  }
  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list"]
  }
}

resource "kubernetes_cluster_role_binding" "external_dns" {
  metadata {
    name = "external-dns"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "external-dns"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "external-dns"
    namespace = kubernetes_namespace.external_dns.metadata[0].name
  }
}

resource "kubernetes_deployment" "external_dns" {
  metadata {
    namespace = kubernetes_namespace.external_dns.metadata[0].name
    name      = "external-dns"
  }
  spec {
    strategy {
      type = "Recreate"
    }
    selector {
      match_labels = {
        app = "external-dns"
      }
    }
    template {
      metadata {
        labels = {
          app = "external-dns"
        }
      }
      spec {
        service_account_name = "external-dns"
        container {
          name  = "external-dns"
          image = "k8s.gcr.io/external-dns/external-dns:v${var.external_dns_version}"
          args = [
            "--source=ingress",
            "--domain-filter=iskprinter.com",
            "--provider=google",
            "--google-project=${var.project}",
            "--registry=txt",
            "--txt-owner-id=my-identifier",
          ]
        }
      }
    }
  }
}
