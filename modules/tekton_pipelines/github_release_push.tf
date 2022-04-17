# Triggers

resource "kubectl_manifest" "trigger_github_release_push" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "Trigger"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-release-push"
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
                "push"
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
              value = "(requestURL.parseURL().path == \"/github/releases\") && (body.ref == \"refs/heads/main\")"
            }
          ]
        }
      ]
      bindings = [
        {
          kind = "TriggerBinding"
          ref  = "github-push"
        }
      ]
      template = {
        ref = "github-release-push"
      }
    }
  })
}

# TriggerTemplates

resource "kubectl_manifest" "trigger_template_github_release_push" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
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
            serviceAccountName = kubernetes_service_account.cicd_bot.metadata[0].name
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

# Pipelines

resource "kubectl_manifest" "pipeline_github_release_push" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
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
            "github-checkout-commit",
            "get-secret-api-client-id",
            "get-secret-api-client-secret"
          ]
          name = "terragrunt-apply"
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
            name = "terragrunt-apply"
          }
        }
      ]
    }
  })
}
