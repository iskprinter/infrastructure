# Triggers

resource "kubectl_manifest" "trigger_github_image_pr" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "Trigger"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-image-pr"
    }
    spec = {
      interceptors = [
        {
          ref = {
            kind = "ClusterInterceptor"
            name = "github"
          }
          params = [
            {
              name = "eventTypes"
              value = [
                "pull_request"
              ]
            },
            {
              name = "secretRef"
              value = {
                secretName = "github-webhook-secret"
                secretKey  = "secret"
              }
            }
          ]
        },
        {
          name = "only when image PRs are opened"
          ref = {
            kind = "ClusterInterceptor"
            name = "cel"
          }
          params = [
            {
              name  = "filter"
              value = "(requestURL.parseURL().path == \"/github/images\") && (body.action in ['opened', 'synchronize', 'reopened'])"
            }
          ]
        }
      ]
      bindings = [
        {
          kind = "TriggerBinding"
          ref  = "github-pr"
        }
      ]
      template = {
        ref = "github-image-pr"
      }
    }
  })
}

# TriggerTemplates

resource "kubectl_manifest" "trigger_template_github_image_pr" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
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
            serviceAccountName = kubernetes_service_account.cicd_bot.metadata[0].name
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

# Pipelines

resource "kubectl_manifest" "pipeline_github_image_pr" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Pipeline"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-image-pr"
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
          description = "The number of the PR to build"
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
              value = kubernetes_secret.cicd_bot_personal_access_token.metadata[0].name
            },
            {
              name  = "secret-namespace"
              value = kubernetes_secret.cicd_bot_personal_access_token.metadata[0].namespace
            }
          ]
        },
        {
          runAfter = [
            "get-secret-github-token"
          ]
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
              value = var.cicd_bot_github_username
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
              value = var.cicd_bot_github_username
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
              name      = "default"
              workspace = "default" # Must match above
            }
          ]
        },
        {
          runAfter = [
            "report-initial-status",
            "github-checkout-commit"
          ]
          name = "build-and-push-image"
          taskRef = {
            name = "build-and-push-image"
          }
          params = [
            {
              name  = "image-name"
              value = "$(params.repo-name)"
            },
            {
              name  = "image-tag"
              value = "$(tasks.github-get-pr-sha.results.revision)"
            }
          ]
          workspaces = [
            {
              name      = "default"
              workspace = "default" # Must match above
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
              value = var.cicd_bot_github_username
            },
            {
              name  = "tekton-pipeline-status"
              value = "$(tasks.status)"
            }
          ]
          taskRef = {
            name = "report-status"
          }
        }
      ]
    }
  })
}
