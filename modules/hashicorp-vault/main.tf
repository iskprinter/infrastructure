resource "google_service_account" "hashicorp_vault" {
  project      = var.gcp_project.name
  account_id   = "hashicorp-vault"
  display_name = "Hashicorp Vault Service Account"
}

resource "google_service_account_iam_member" "hashicorp_vault_iam_workload_identity_user_member" {
  service_account_id = google_service_account.hashicorp_vault.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project.name}.svc.id.goog[${helm_release.hashicorp_vault.namespace}/hashicorp-vault]"
}

resource "google_project_iam_custom_role" "hashicorp_vault_role" {
  project = var.gcp_project.name
  role_id = "hashicorp_vault"
  title   = "Hashicorp Vault"
  permissions = [
    "cloudkms.cryptoKeyVersions.useToEncrypt",
    "cloudkms.cryptoKeyVersions.useToDecrypt",
    "cloudkms.cryptoKeys.get",
  ]
}

resource "google_project_iam_member" "hashicorp_vault_role_member" {
  project = var.gcp_project.name
  role    = google_project_iam_custom_role.hashicorp_vault_role.name
  member  = "serviceAccount:${google_service_account.hashicorp_vault.email}"
}

resource "google_kms_key_ring" "hashicorp_vault" {
  project  = var.gcp_project.name
  location = var.gcp_project.region
  name     = "hashicorp-vault"
}

resource "google_kms_crypto_key" "hashicorp_vault_recovery_key" {
  name     = "hashicorp-vault-recovery-key"
  key_ring = google_kms_key_ring.hashicorp_vault.id
}

resource "helm_release" "hashicorp_vault" {
  name             = "hashicorp-vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = var.hashicorp_vault_version
  namespace        = "hashicorp-vault"
  create_namespace = true

  set {
    name  = "server.extraEnvironmentVars.VAULT_SEAL_TYPE"
    value = "gcpckms"
  }
  set {
    name  = "server.extraEnvironmentVars.GOOGLE_PROJECT"
    value = var.gcp_project.name
  }
  set {
    name  = "server.extraEnvironmentVars.GOOGLE_REGION"
    value = var.gcp_project.region
  }
  set {
    name  = "server.extraEnvironmentVars.VAULT_GCPCKMS_SEAL_KEY_RING"
    value = google_kms_key_ring.hashicorp_vault.name
  }
  set {
    name  = "server.extraEnvironmentVars.VAULT_GCPCKMS_SEAL_CRYPTO_KEY"
    value = google_kms_crypto_key.hashicorp_vault_recovery_key.name
  }
  set {
    name  = "server.serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
    value = google_service_account.hashicorp_vault.email
  }
}
