resource "kubernetes_manifest" "event_listener_github" {
  manifest = {
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
              metadata = {
                creationTimestamp = null
              }
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
  lifecycle {
    ignore_changes = [
      object.spec.resources.kubernetesResource.spec.template.metadata.creationTimestamp,
    ]
  }
}
