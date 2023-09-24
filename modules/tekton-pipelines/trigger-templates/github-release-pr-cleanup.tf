resource "kubernetes_manifest" "trigger_template_github_release_pr_cleanup" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerTemplate"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-release-pr-cleanup"
    }
    spec = {
      params = [
        {
          name        = "pr-number"
          description = "The number of the PR to clean up"
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
            generateName = "github-release-pr-cleanup-"
          }
          spec = {
            pipelineRef = {
              name = "github-release-pr-cleanup"
            }
            params = [
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
              },
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
