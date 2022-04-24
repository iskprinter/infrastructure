resource "kubectl_manifest" "trigger_template_github_image_pr" {
    yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerTemplate"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-image-pr"
    }
    spec = {
      params = [
        {
          name = "github-status-url"
        },
        {
          name = "pr-number"
        },
        {
          name = "repo-name"
        },
        {
          name = "repo-url"
        }
      ]
      resourcetemplates = [
        {
          apiVersion = "tekton.dev/v1beta1"
          kind       = "PipelineRun"
          metadata = {
            generateName = "github-image-pr-"
          }
          spec = {
            serviceAccountName = var.cicd_bot_name
            pipelineRef = {
              name = "github-image-pr"
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
