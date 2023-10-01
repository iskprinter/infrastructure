resource "kubernetes_ingress_v1" "tekton_triggers_ingress" {
  metadata {
    name      = "tekton-triggers-ingress"
    namespace = "tekton-pipelines"
    annotations = {
      "cert-manager.io/cluster-issuer" = "lets-encrypt"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "tekton-triggers.${var.domain_name}"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "el-github"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    tls {
      hosts = [
        "tekton-triggers.${var.domain_name}"
      ]
      secret_name = "tls-tekton-triggers-${replace(var.domain_name, ".", "-")}"
    }
  }
}
