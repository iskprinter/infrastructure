resource "kubernetes_namespace" "iskprinter" {
  metadata {
    name = "iskprinter"
  }
}

resource "kubernetes_role" "releaser" {
  metadata {
    namespace = "iskprinter"
    name      = "releaser"
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["create", "get", "patch", "update", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "get", "patch", "update", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["create", "get", "patch", "update", "delete"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs"]
    verbs      = ["create", "get", "patch", "update", "delete"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["create", "get", "patch", "update", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    resource_names = [
      var.api_client_credentials_secret_name,
      var.mongodb_connection_secret_name,
    ]
    verbs = ["get"]
  }
}

resource "kubernetes_role_binding" "releasers" {
  metadata {
    namespace = "iskprinter"
    name      = "releasers"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "releaser"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = var.cicd_namespace
    name      = var.cicd_bot_name
  }
}
