resource "kubernetes_manifest" "trigger_template_github_release_push" {
  manifest = {
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
      resourceTemplates = [
        {
          apiVersion = "tekton.dev/v1"
          kind       = "PipelineRun"
          metadata = {
            generateName = "github-release-push-"
          }
          spec = {
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
            taskRunTemplate = {
              serviceAccountName = var.cicd_bot_name
            }
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
  }
}
