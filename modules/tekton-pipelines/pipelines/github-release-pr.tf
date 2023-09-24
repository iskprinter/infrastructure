resource "kubernetes_manifest" "pipeline_github_release_pr" {
  manifest = {
    apiVersion = "tekton.dev/v1"
    kind       = "Pipeline"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-release-pr"
    }
    spec = {
      params = [
        {
          name        = "github-status-url"
          type        = "string"
          description = "The GitHub status URL"
        },
        {
          name        = "pr-number"
          type        = "string"
          description = "The number to of the PR to build"
        },
        {
          name        = "repo-name"
          type        = "string"
          description = "The name of the repo to build"
        },
        {
          name        = "repo-url"
          type        = "string"
          description = "The URL of the repo to build"
        }
      ]
      workspaces = [
        {
          name = "default" # Must match the name in the PipelineRun?
        }
      ]
      tasks = [
        {
          name = "get-secret-github-token"
          taskRef = {
            kind = "Task"
            name = "get-secret"
          }
          params = [
            {
              name  = "secret-key"
              value = "password"
            },
            {
              name  = "secret-name"
              value = "cicd-bot-personal-access-token"
            },
            {
              name  = "secret-namespace"
              value = "tekton-pipelines"
            }
          ]
        },
        {
          name = "report-initial-status"
          taskRef = {
            kind = "Task"
            name = "report-status"
          }
          params = [
            {
              name  = "github-status-url"
              value = "$(params.github-status-url)"
            },
            {
              name  = "github-token"
              value = "$(tasks.get-secret-github-token.results.secret-value)"
            },
            {
              name  = "github-username"
              value = "IskprinterGitBot"
            },
            {
              name  = "tekton-pipeline-status"
              value = "None"
            }
          ]
        },
        {
          runAfter = [
            "get-secret-github-token"
          ]
          name = "github-get-pr-sha"
          taskRef = {
            kind = "Task"
            name = "github-get-pr-sha"
          }
          params = [
            {
              name  = "github-token"
              value = "$(tasks.get-secret-github-token.results.secret-value)"
            },
            {
              name  = "github-username"
              value = "IskprinterGitBot"
            },
            {
              name  = "pr-number"
              value = "$(params.pr-number)"
            },
            {
              name  = "repo-name"
              value = "$(params.repo-name)"
            }
          ]
        },
        {
          runAfter = [
            "github-get-pr-sha",
          ]
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
              value = "$(tasks.github-get-pr-sha.results.revision)"
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
            "github-checkout-commit",
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
              value = "pr"
            },
            {
              name  = "pr-number"
              value = "$(params.pr-number)"
            }
          ]
        },
        {
          runAfter = [
            "report-initial-status",
            "github-checkout-commit",
          ]
          name = "acceptance-test-get-image"
          workspaces = [
            {
              name      = "default"
              workspace = "default" # Must match above
            }
          ]
          taskRef = {
            kind = "Task"
            name = "acceptance-test-get-image"
          }
        },
        {
          runAfter = [
            "terragrunt-apply",
            "acceptance-test-get-image",
          ]
          name = "acceptance-test-run"
          taskRef = {
            kind = "Task"
            name = "acceptance-test-run"
          }
          params = [
            {
              name  = "acceptance-test-image"
              value = "$(tasks.acceptance-test-get-image.results.acceptance-test-image)"
            },
            {
              name  = "pr-number"
              value = "$(params.pr-number)"
            }
          ]
        }
      ]
      finally = [
        {
          name = "report-final-status"
          params = [
            {
              name  = "github-status-url"
              value = "$(params.github-status-url)"
            },
            {
              name  = "github-token"
              value = "$(tasks.get-secret-github-token.results.secret-value)"
            },
            {
              name  = "github-username"
              value = "IskprinterGitBot"
            },
            {
              name  = "tekton-pipeline-status"
              value = "$(tasks.status)"
            }
          ]
          taskRef = {
            kind = "Task"
            name = "report-status"
          }
        },
        {
          name = "terragrunt-destroy"
          workspaces = [
            {
              name      = "default"
              workspace = "default" # Must match above
            }
          ]
          taskRef = {
            kind = "Task"
            name = "terragrunt-destroy"
          }
          params = [
            {
              name  = "env-name"
              value = "pr"
            },
            {
              name  = "pr-number"
              value = "$(params.pr-number)"
            }
          ]
        },
      ]
    }
  }
}
