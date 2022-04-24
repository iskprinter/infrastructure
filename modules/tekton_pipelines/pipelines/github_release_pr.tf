resource "kubectl_manifest" "pipeline_github_release_pr" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
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
            "report-initial-status",
            "github-checkout-commit",
          ]
          name = "namespace-create"
          taskRef = {
            name = "namespace-create"
          },
          params = [
            {
              name  = "namespace"
              value = "iskprinter-pr-$(params.pr-number)"
            }
          ]
        },
        {
          runAfter = [
            "namespace-create",
          ]
          name = "terragrunt-plan"
          workspaces = [
            {
              name      = "default"
              workspace = "default" # Must match above
            }
          ]
          taskRef = {
            name = "terragrunt-plan"
          }
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
            name = "acceptance-test-get-image"
          }
        },
        # {
        #   runAfter = [
        #     "terragrunt-plan",
        #     "acceptance-test-get-image",
        #   ]
        #   name = "acceptance-test-run"
        #   taskRef = {
        #     name = "acceptance-test-run"
        #   }
        #   params = [
        #     {
        #       name  = "acceptance-test-image"
        #       value = "$(tasks.acceptance-test-get-image.acceptance-test-image)"
        #     },
        #     {
        #       name  = "pr-number"
        #       value = "$(params.pr-number)"
        #     }
        #   ]
        # }
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
            name = "report-status"
          }
        },
        {
          name = "namespace-delete"
          taskRef = {
            name = "namespace-delete"
          },
          params = [
            {
              name  = "namespace"
              value = "iskprinter-pr-$(params.pr-number)"
            }
          ]
        }
      ]
    }
  })
}
