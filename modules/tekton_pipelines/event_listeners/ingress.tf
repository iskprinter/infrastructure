resource "kubernetes_ingress" "tekton_triggers_ingress" {
  metadata {
    name      = "tekton-triggers-ingress"
    namespace = "tekton-pipelines"
    annotations = {
      "cert-manager.io/cluster-issuer"           = "lets-encrypt"
      "kubernetes.io/ingress.class"              = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }
  spec {
    rule {
      host = "tekton-triggers.iskprinter.com"
      http {
        path {
          path = "/"
          backend {
            service_name = "el-github"
            service_port = 8080
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
