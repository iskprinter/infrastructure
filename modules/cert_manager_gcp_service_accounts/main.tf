resource "google_service_account" "cert_manager" {
  project      = var.project
  account_id   = var.cert_manager_gcp_service_account_name
  display_name = "Certificate Manager Service Account"
}

resource "google_service_account_iam_member" "service_account_iam_workload_identity_user_binding" {
  service_account_id = google_service_account.cert_manager.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${var.cert_manager_kubernetes_namespace}/${var.cert_manager_kubernetes_service_account_name}]"
}

resource "google_project_iam_member" "service_account_dns_record_sets_binding" {
  project = var.project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cert_manager.email}"
}
