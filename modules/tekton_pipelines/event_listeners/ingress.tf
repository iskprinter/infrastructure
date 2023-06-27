resource "kubernetes_ingress_v1" "tekton_triggers_ingress" {
  metadata {
    name      = "tekton-triggers-ingress"
    namespace = "tekton-pipelines"
    annotations = {
      "cert-manager.io/cluster-issuer"           = "lets-encrypt"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "tekton-triggers.iskprinter.com"
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
        "tekton-triggers.iskprinter.com"
      ]
      secret_name = "tls-tekton-triggers-iskprinter-com"
    }
  }
}
