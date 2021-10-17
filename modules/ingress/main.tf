resource "helm_release" "nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.nginx_version
  namespace        = "ingress"
  create_namespace = true
}

data "kubernetes_service" "nginx" {
  metadata {
    namespace = helm_release.nginx.namespace
    name      = "ingress-nginx-controller"
  }
}
