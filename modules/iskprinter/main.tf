locals {
  api_client_credentials_secret_key_id     = "id"
  api_client_credentials_secret_key_secret = "secret"
  api_client_credentials_secret_name       = "api-client-credentials"
}

resource "kubernetes_namespace" "iskprinter" {
  metadata {
    name = "iskprinter"
  }
}

resource "kubernetes_secret" "api_client_credentials" {
  type = "Opaque"
  metadata {
    namespace = "iskprinter"
    name      = local.api_client_credentials_secret_name
  }
  binary_data = {
    (local.api_client_credentials_secret_key_id)     = base64encode(var.api_client_id)
    (local.api_client_credentials_secret_key_secret) = var.api_client_secret_base64
  }
}

resource "google_project_iam_member" "service_account_dns_record_sets_binding" {
  project = var.project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${var.google_service_account_cicd_bot_email}"
}

resource "kubernetes_role" "releaser_database" {
  metadata {
    namespace = "database"
    name      = "releaser"
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["get"]
  }
  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["rolebindings", "roles"]
    verbs      = ["get"]
  }
  rule {
    api_groups = ["mongodbcommunity.mongodb.com"]
    resources  = ["mongodbcommunity"]
    verbs      = ["get"]
  }
}

resource "kubernetes_role_binding" "releasers_database" {
  metadata {
    namespace = "database"
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

resource "kubernetes_role" "releaser_iskprinter" {
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
    resources  = ["serviceaccounts"]
    verbs      = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get"]
  }
}

resource "kubernetes_role_binding" "releasers_iskprinter" {
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

resource "kubernetes_role" "releaser_ingress" {
  metadata {
    namespace = "ingress"
    name      = "releaser"
  }
  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get"]
  }
}

resource "kubernetes_role_binding" "releasers_ingress" {
  metadata {
    namespace = "ingress"
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
