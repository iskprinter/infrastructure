resource "helm_release" "nginx" {
  name             = "nginx-ingress"
  repository       = "https://helm.nginx.com/stable"
  chart            = "nginx-ingress"
  version          = var.nginx_version
  namespace        = "ingress"
  create_namespace = true
}

data "kubernetes_service" "nginx" {
  metadata {
    namespace = helm_release.nginx.namespace
    name      = "${helm_release.nginx.chart}-${helm_release.nginx.name}"
  }
}
