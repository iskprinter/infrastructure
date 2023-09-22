locals {
  cert_manager_operator_version                = "1.12.2" # The helm chart version
  cert_manager_operator_namespace              = "cert-manager-operator"
  cert_manager_kubernetes_service_account_name = "cert-manager"
  external_secrets_version                     = "0.9.0" # The helm chart version
  hashicorp_vault_version                      = "0.24.1" # The helm chart version
  mongodb_operator_version                     = "0.8.0" # The helm chart version
}
