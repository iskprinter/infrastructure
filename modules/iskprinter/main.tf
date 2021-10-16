resource "kubernetes_namespace" "iskprinter" {
  metadata {
    name = "iskprinter"
  }
}

resource "kubernetes_manifest" "certificate_iskprinter_com" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      namespace = kubernetes_namespace.iskprinter.metadata[0].name
      name      = "iskprinter-com"
    }
    spec = {
      secretName = "tls-iskprinter-com"
      issuerRef = {
        # The issuer created previously
        kind = "ClusterIssuer"
        name = "lets-encrypt-prod"
      }
      dnsNames = ["iskprinter.com"]
    }
  }
}

resource "kubernetes_manifest" "certificate_www_iskprinter_com" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      namespace = kubernetes_namespace.iskprinter.metadata[0].name
      name      = "www-iskprinter-com"
    }
    spec = {
      secretName = "tls-www-iskprinter-com"
      issuerRef = {
        # The issuer created previously
        kind = "ClusterIssuer"
        name = "lets-encrypt-prod"
      }
      dnsNames = ["www.iskprinter.com"]
    }
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
    verbs      = ["create", "get", "update", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "get", "update", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["create", "get", "update", "delete"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs"]
    verbs      = ["create", "get", "update", "delete"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["create", "get", "update", "delete"]
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
