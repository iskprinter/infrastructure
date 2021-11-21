locals {
  api_client_credentials_secret_key_id     = "id"
  api_client_credentials_secret_key_secret = "secret"
}

resource "kubernetes_namespace" "secrets" {
  metadata {
    name = "secrets"
  }
}

resource "kubernetes_secret" "api_client_credentials" {
  type = "Opaque"
  metadata {
    namespace = kubernetes_namespace.secrets.metadata[0].name
    name      = "api-client-credentials"
  }
  binary_data = {
    (local.api_client_credentials_secret_key_id)     = base64encode(var.api_client_id)
    (local.api_client_credentials_secret_key_secret) = var.api_client_secret_base64
  }
}

resource "kubernetes_role" "cicd_bot" {
  depends_on = [
    kubernetes_namespace.secrets,
  ]
  metadata {
    namespace = kubernetes_namespace.secrets.metadata[0].name
    name      = "cicd-bot"
  }
  # EventListeners need to be able to fetch all namespaced resources
  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = [kubernetes_secret.api_client_credentials.metadata[0].name]
    verbs          = ["get"]
  }
}

resource "kubernetes_role_binding" "cicd_bot" {
  metadata {
    namespace = kubernetes_role.cicd_bot.metadata[0].namespace
    name      = "cicd-bot"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = var.cicd_namespace
    name      = var.cicd_bot_name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.cicd_bot.metadata[0].name
  }
}
