resource "kubectl_manifest" "trigger_template_github_release_push" {
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerTemplate"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-release-push"
    }
    spec = {
      params = [
        {
          name = "repo-url"
        },
        {
          name = "revision"
        }
      ]
      resourcetemplates = [
        {
          apiVersion = "tekton.dev/v1beta1"
          kind       = "PipelineRun"
          metadata = {
            generateName = "github-release-push-"
          }
          spec = {
            serviceAccountName = var.cicd_bot_name
            pipelineRef = {
              name = "github-release-push"
            }
            params = [
              {
                name  = "repo-url"
                value = "$(tt.params.repo-url)"
              },
              {
                name  = "revision"
                value = "$(tt.params.revision)"
              }
            ]
            workspaces = [
              {
                name = "default"
                volumeClaimTemplate = {
                  spec = {
                    accessModes = [
                      "ReadWriteOnce"
                    ]
                    resources = {
                      requests = {
                        storage = "512Mi"
                      }
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  })
}
