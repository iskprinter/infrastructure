locals {
  user_accounts = [
    {
      account_id   = "minikube-image-puller"
      display_name = "Minikube Image Puller"
    }
  ]
}

resource "google_service_account" "service_account" {
  for_each     = { for i, account in local.user_accounts : account.account_id => account }
  project      = var.project
  account_id   = each.value.account_id
  display_name = each.value.display_name
}

resource "google_project_iam_custom_role" "container_image_reader_role" {
  project = var.project
  role_id = "container_image_reader"
  title   = "Container Image Reader"
  permissions = [
    "artifactregistry.repositories.downloadArtifacts"
  ]
}

resource "google_project_iam_member" "developer_role" {
  for_each = google_service_account.service_account
  project  = var.project
  role     = google_project_iam_custom_role.container_image_reader_role.name
  member   = "serviceAccount:${each.value.email}"
}
