resource "helm_release" "hashcorp_vault" {
  name             = "hashicorp-vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = var.hashicorp_vault_version
  namespace        = "hashicorp-vault"
  create_namespace = true
  set {
    name  = "ui.enabled"
    value = true
  }
}

resource "kubernetes_ingress" "hashcorp_vault" {
  wait_for_load_balancer = true
  metadata {
    namespace = helm_release.hashcorp_vault.namespace
    name      = "hashicorp-vault"
    annotations = {
      "cert-manager.io/cluster-issuer" = "lets-encrypt"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "vault.iskprinter.com"
      http {
        path {
          path = "/"
          backend {
            service_name = "hashicorp-vault-ui"
            service_port = 8200
          }
        }
      }
    }
    tls {
      hosts       = ["vault.iskprinter.com"]
      secret_name = "tls-api"
    }
  }
}
