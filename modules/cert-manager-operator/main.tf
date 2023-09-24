locals {
  cert_manager_kubernetes_service_account_name = "cert-manager"
}

resource "google_service_account" "cert_manager" {
  count        = (var.kubernetes_provider == "gcp" ? 1 : 0)
  project      = var.project
  account_id   = "cert-manager"
  display_name = "Certificate Manager Service Account"
}

resource "google_service_account_iam_member" "service_account_iam_workload_identity_user_binding" {
  count              = (var.kubernetes_provider == "gcp" ? 1 : 0)
  service_account_id = google_service_account.cert_manager[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${var.cert_manager_namespace}/${local.cert_manager_kubernetes_service_account_name}]"
}

resource "google_project_iam_member" "service_account_dns_record_sets_binding" {
  count   = (var.kubernetes_provider == "gcp" ? 1 : 0)
  project = var.project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cert_manager[0].email}"
}

resource "helm_release" "cert_manager_operator" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_operator_version
  namespace        = var.cert_manager_namespace
  create_namespace = true
  set {
    name  = "global.leaderElection.namespace"
    value = var.cert_manager_namespace
  }
  set {
    name  = "installCRDs"
    value = true
  }
  set {
    name  = "prometheus.enabled"
    value = false
  }
  dynamic "set" {
    for_each = (var.kubernetes_provider == "gcp" ? toset([{}]) : toset([]))
    content {
      name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
      value = "${google_service_account.cert_manager[0].name}@${var.project}.iam.gserviceaccount.com"
    }
  }
}
