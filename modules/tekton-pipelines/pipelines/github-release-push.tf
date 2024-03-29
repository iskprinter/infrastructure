resource "kubernetes_manifest" "pipeline_github_release_push" {
  manifest = {
    apiVersion = "tekton.dev/v1"
    kind       = "Pipeline"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-release-push"
    }
    spec = {
      params = [
        {
          name        = "repo-url"
          type        = "string"
          description = "The URL of the repo to build"
        },
        {
          name        = "revision"
          type        = "string"
          description = "The revision to of the repo to build"
        }
      ]
      workspaces = [
        {
          name = "default" # Must match the name in the PipelineRun?
        }
      ]
      tasks = [
        {
          name = "github-checkout-commit"
          taskRef = {
            kind = "Task"
            name = "github-checkout-commit"
          }
          params = [
            {
              name  = "repo-url"
              value = "$(params.repo-url)"
            },
            {
              name  = "revision"
              value = "$(params.revision)"
            }
          ]
          workspaces = [
            {
              name      = "default" # Must match what the git-clone task expects.
              workspace = "default" # Must match above
            }
          ]
        },
        {
          runAfter = [
            "github-checkout-commit"
          ]
          name = "terragrunt-apply"
          workspaces = [
            {
              name      = "default"
              workspace = "default" # Must match above
            }
          ]
          taskRef = {
            kind = "Task"
            name = "terragrunt-apply"
          }
          params = [
            {
              name  = "env-name"
              value = "prod"
            }
          ]
        }
      ]
    }
  }
}
