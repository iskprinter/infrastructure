
# For some reason, this is not working right now.
# I created a question on the helm provider gitub repo:
# https://github.com/hashicorp/terraform-provider-helm/issues/783
# As a workaround, I deployed it manually, with:
# helm install -n ingress nginx-ingress nginx-stable/nginx-ingress --set controller.replicaCount=2

provider "helm" {
  kubernetes {
    # host                   = "https://${var.cluster_endpoint}"
    config_path            = "~/.kube/config"
    # client_certificate     = var.cluster_client_certificate
    # client_key             = var.cluster_client_key
    # cluster_ca_certificate = var.cluster_ca_certificate
  }
}

provider "kubernetes" {
  # host                   = "https://${var.cluster_endpoint}"
  config_path            = "~/.kube/config"
  # client_certificate     = var.cluster_client_certificate
  # client_key             = var.cluster_client_key
  # cluster_ca_certificate = var.cluster_ca_certificate
}

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
    name      = "${helm_release.nginx.name}-${helm_release.nginx.chart}"
  }
}
