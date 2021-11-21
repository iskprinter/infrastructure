
resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress"
  }
}

resource "helm_release" "nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.nginx_version
  namespace  = kubernetes_namespace.ingress.metadata[0].name
}

data "kubernetes_service" "nginx" {
  metadata {
    namespace = helm_release.nginx.namespace
    name      = "ingress-nginx-controller"
  }
}

resource "kubernetes_role" "cicd_bot_ingress" {
  depends_on = [
    kubernetes_namespace.ingress
  ]

  metadata {
    namespace = kubernetes_namespace.ingress.metadata[0].name
    name      = "releaser"
  }
  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get"]
  }
}

resource "kubernetes_role_binding" "cicd_bot_ingress" {
  depends_on = [
    kubernetes_namespace.ingress
  ]

  metadata {
    namespace = kubernetes_namespace.ingress.metadata[0].name
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
