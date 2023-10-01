resource "kubernetes_manifest" "event_listener_github" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "EventListener"
    metadata = {
      name      = "github"
      namespace = "tekton-pipelines"
    }
    spec = {
      namespaceSelector  = {}
      serviceAccountName = var.cicd_bot_name
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
                serviceAccountName = var.cicd_bot_name
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
  }
}
