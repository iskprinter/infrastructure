locals {
  cert_manager_namespace        = "cert-manager"
  cert_manager_operator_version = "1.13.0" # The helm chart version, from https://artifacthub.io/packages/helm/cert-manager/cert-manager
  external_secrets_version      = "0.9.5"  # The helm chart version, from https://external-secrets.io/latest/
  hashicorp_vault_version       = "0.25.0" # The helm chart version, from https://github.com/hashicorp/vault-helm/releases/tag/v0.25.0
  mongodb_operator_version      = "0.8.2"  # The helm chart version, from https://github.com/mongodb/helm-charts/releases
}
