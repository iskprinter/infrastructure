resource "google_service_account" "hashicorp_vault" {
  count        = var.gcp_configuration == null ? 0 : 1
  project      = var.gcp_configuration.project
  account_id   = "hashicorp-vault"
  display_name = "Hashicorp Vault Service Account"
}

resource "google_service_account_iam_member" "hashicorp_vault_iam_workload_identity_user_member" {
  count              = var.gcp_configuration == null ? 0 : 1
  service_account_id = google_service_account.hashicorp_vault[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_configuration.project}.svc.id.goog[${helm_release.hashicorp_vault.namespace}/hashicorp-vault]"
}

resource "google_project_iam_custom_role" "hashicorp_vault_role" {
  count   = var.gcp_configuration == null ? 0 : 1
  project = var.gcp_configuration.project
  role_id = "hashicorp_vault"
  title   = "Hashicorp Vault"
  permissions = [
    "cloudkms.cryptoKeyVersions.useToEncrypt",
    "cloudkms.cryptoKeyVersions.useToDecrypt",
    "cloudkms.cryptoKeys.get",
  ]
}

resource "google_project_iam_member" "cicd_bot_role_member" {
  count   = var.gcp_configuration == null ? 0 : 1
  project = var.gcp_configuration.project
  role    = google_project_iam_custom_role.hashicorp_vault_role[0].name
  member  = "serviceAccount:${google_service_account.hashicorp_vault[0].email}"
}

resource "google_kms_key_ring" "hashicorp_vault" {
  count    = var.gcp_configuration == null ? 0 : 1
  project  = var.gcp_configuration.project
  location = var.gcp_configuration.region
  name     = "hashicorp-vault"
}

resource "google_kms_crypto_key" "hashicorp_vault_recovery_key" {
  count    = var.gcp_configuration == null ? 0 : 1
  name     = "hashicorp-vault-recovery-key"
  key_ring = google_kms_key_ring.hashicorp_vault[0].id
  lifecycle {
    prevent_destroy = true
  }
}

resource "helm_release" "hashicorp_vault" {
  name             = "hashicorp-vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = var.hashicorp_vault_version
  namespace        = "hashicorp-vault"
  create_namespace = true

  dynamic "set" {
    for_each = var.gcp_configuration == null ? [] : [0]
    content {
      name  = "server.extraEnvironmentVars.VAULT_SEAL_TYPE"
      value = "gcpckms"
    }
  }
  dynamic "set" {
    for_each = var.gcp_configuration == null ? [] : [0]
    content {
      name  = "server.extraEnvironmentVars.GOOGLE_PROJECT"
      value = var.gcp_configuration.project
    }
  }
  dynamic "set" {
    for_each = var.gcp_configuration == null ? [] : [0]
    content {
      name  = "server.extraEnvironmentVars.GOOGLE_REGION"
      value = var.gcp_configuration.region
    }
  }
  dynamic "set" {
    for_each = var.gcp_configuration == null ? [] : [0]
    content {
      name  = "server.extraEnvironmentVars.VAULT_GCPCKMS_SEAL_KEY_RING"
      value = google_kms_key_ring.hashicorp_vault[0].name
    }
  }
  dynamic "set" {
    for_each = var.gcp_configuration == null ? [] : [0]
    content {
      name  = "server.extraEnvironmentVars.VAULT_GCPCKMS_SEAL_CRYPTO_KEY"
      value = google_kms_crypto_key.hashicorp_vault_recovery_key[0].name
    }
  }
  dynamic "set" {
    for_each = var.gcp_configuration == null ? [] : [0]
    content {
      name  = "server.serviceaccount.annotations.iam\\.gke\\.io/gcp-service-account"
      value = google_service_account.hashicorp_vault[0].email
    }
  }
}
