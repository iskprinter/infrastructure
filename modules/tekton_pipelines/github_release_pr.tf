# Triggers

resource "kubectl_manifest" "trigger_github_release_pr" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "Trigger"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-release-pr"
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
              value = "(requestURL.parseURL().path == \"/github/releases\") && (body.action in ['opened', 'synchronize', 'reopened'])"
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
        ref = "github-release-pr"
      }
    }
  })
}

resource "kubectl_manifest" "trigger_github_release_pr_cleanup" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "Trigger"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-release-pr-cleanup"
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
          name = "only when release PRs are closed"
          ref = {
            kind = "ClusterInterceptor"
            name = "cel"
          }
          params = [
            {
              name  = "filter"
              value = "(requestURL.parseURL().path == \"/github/releases\") && (body.action in ['closed'])"
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
        ref = "github-release-pr-cleanup"
      }
    }
  })
}

# TriggerTemplates

resource "kubectl_manifest" "trigger_template_github_release_pr" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
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
      resourcetemplates = [
        {
          apiVersion = "tekton.dev/v1beta1"
          kind       = "PipelineRun"
          metadata = {
            generateName = "github-release-pr-"
          }
          spec = {
            serviceAccountName = kubernetes_service_account.cicd_bot.metadata[0].name
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

resource "kubectl_manifest" "trigger_template_github_release_pr_cleanup" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
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
      resourcetemplates = [
        {
          apiVersion = "tekton.dev/v1beta1"
          kind       = "PipelineRun"
          metadata = {
            generateName = "github-release-pr-cleanup-"
          }
          spec = {
            serviceAccountName = kubernetes_service_account.cicd_bot.metadata[0].name
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

resource "kubectl_manifest" "pipeline_github_release_pr" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
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
              value = kubernetes_secret.cicd_bot_personal_access_token.metadata[0].name
            },
            {
              name  = "secret-namespace"
              value = kubernetes_secret.cicd_bot_personal_access_token.metadata[0].namespace
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
              name      = "default" # Must match what the git-clone task expects.
              workspace = "default" # Must match above
            }
          ]
        },
        {
          name = "get-secret-api-client-id"
          taskRef = {
            name = "get-secret"
          }
          params = [
            {
              name  = "secret-key"
              value = "id"
            },
            {
              name  = "secret-name"
              value = "api-client-credentials"
            },
            {
              name  = "secret-namespace"
              value = "secrets"
            }
          ]
        },
        {
          name = "get-secret-api-client-secret"
          taskRef = {
            name = "get-secret"
          }
          params = [
            {
              name  = "secret-key"
              value = "secret"
            },
            {
              name  = "secret-name"
              value = "api-client-credentials"
            },
            {
              name  = "secret-namespace"
              value = "secrets"
            }
          ]
        },
        {
          runAfter = [
            "report-initial-status",
            "github-checkout-commit",
            "get-secret-api-client-id",
            "get-secret-api-client-secret",
          ]
          name = "terragrunt-plan"
          params = [
            {
              name  = "api-client-id"
              value = "$(tasks.get-secret-api-client-id.results.secret-value)"
            },
            {
              name  = "api-client-secret"
              value = "$(tasks.get-secret-api-client-secret.results.secret-value)"
            },
          ]
          workspaces = [
            {
              name      = "default"
              workspace = "default" # Must match above
            }
          ]
          taskRef = {
            name = "terragrunt-plan"
          }
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
