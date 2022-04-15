locals {
  developers = [
    {
      account_id   = "cameronhudson"
      display_name = "Cameron Hudson"
    }
  ]
}

resource "google_service_account" "service_account" {
  for_each     = { for i, dev in local.developers : dev.account_id => dev }
  project      = var.project
  account_id   = each.value.account_id
  display_name = each.value.display_name
}

resource "google_project_iam_custom_role" "developer_role" {
  project = var.project
  role_id = "developer"
  title   = "Developer"
  permissions = [
    "artifactregistry.repositories.downloadArtifacts"
  ]
}

resource "google_project_iam_member" "developer_role" {
  for_each = google_service_account.service_account
  project  = var.project
  role     = google_project_iam_custom_role.developer_role.name
  member   = "serviceAccount:${each.value.email}"
}
