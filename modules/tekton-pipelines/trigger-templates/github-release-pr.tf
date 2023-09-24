resource "kubernetes_manifest" "trigger_template_github_release_pr" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerTemplate"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-release-pr"
    }
    spec = {
      params = [
        {
          name        = "github-status-url"
          description = "The status URL for the GitHub pull request"
        },
        {
          name        = "pr-number"
          description = "The GitHub pull request number"

        },
        {
          name        = "repo-name"
          description = "The name of the repo"

        },
        {
          name        = "repo-url"
          description = "The SSH URL of the repo"

        }
      ]
      resourceTemplates = [
        {
          apiVersion = "tekton.dev/v1"
          kind       = "PipelineRun"
          metadata = {
            generateName = "github-release-pr-"
          }
          spec = {
            pipelineRef = {
              name = "github-release-pr"
            }
            params = [
              {
                name  = "github-status-url"
                value = "$(tt.params.github-status-url)"
              },
              {
                name  = "pr-number"
                value = "$(tt.params.pr-number)"
              },
              {
                name  = "repo-name"
                value = "$(tt.params.repo-name)"
              },
              {
                name  = "repo-url"
                value = "$(tt.params.repo-url)"
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
