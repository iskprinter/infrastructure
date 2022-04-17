# Routing

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

# Event Listeners

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubectl_manifest" "event_listener_github" {
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "EventListener"
    metadata = {
      name      = "github"
      namespace = "tekton-pipelines"
      finalizers = [
        "eventlisteners.triggers.tekton.dev",
      ]
    }
    spec = {
      namespaceSelector  = {}
      serviceAccountName = kubernetes_service_account.cicd_bot.metadata[0].name
      triggers = [
        {
          triggerRef = "github-image-pr"
        },
        {
          triggerRef = "github-release-pr"
        },
        {
          triggerRef = "github-release-push"
        }
      ]
      resources = {
        kubernetesResource = {
          spec = {
            template = {
              spec = {
                serviceAccountName = kubernetes_service_account.cicd_bot.metadata[0].name
                containers = [
                  {
                    name = ""
                    resources = {
                      limits = {
                        memory = "64Mi"
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }
  })
}
