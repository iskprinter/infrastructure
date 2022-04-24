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
  })
}
