# Tekton Pipeline

data "google_storage_bucket_object_content" "tekton_pipeline" {
  name   = "pipeline/previous/v${var.tekton_pipeline_version}/release.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton_pipeline" {
  content = data.google_storage_bucket_object_content.tekton_pipeline.content
}

resource "kubectl_manifest" "tekton_pipeline" {
  count            = length(data.kubectl_file_documents.tekton_pipeline.documents)
  yaml_body        = element(data.kubectl_file_documents.tekton_pipeline.documents, count.index)
  wait_for_rollout = false
}

# Tekton Dashboard

data "google_storage_bucket_object_content" "tekton_dashboard" {
  name   = "dashboard/previous/v${var.tekton_dashboard_version}/tekton-dashboard-release.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton_dashboard" {
  content = data.google_storage_bucket_object_content.tekton_dashboard.content
}

resource "kubectl_manifest" "tekton_dashboard" {
  count            = length(data.kubectl_file_documents.tekton_dashboard.documents)
  yaml_body        = element(data.kubectl_file_documents.tekton_dashboard.documents, count.index)
  wait_for_rollout = false
}

# Service account and credentials
# Based on https://github.com/sdaschner/tekton-argocd-example

resource "kubernetes_service_account" "cicd_bot_service_account" {
  metadata {
    name      = "cicd-bot"
    namespace = "tekton-pipelines"
  }
  secret {
    name = "cicd-bot-container-registry-credentials"
  }
  secret {
    name = "cicd-bot-ssh-key"
  }
}

resource "kubernetes_secret" "cicd_bot_ssh_key" {
  type = "kubernetes.io/ssh-auth"
  metadata {
    name      = "cicd-bot-ssh-key"
    namespace = "tekton-pipelines"
    annotations = {
      "tekton.dev/git-0" = "github.com"
    }
  }
  binary_data = {
    ssh-privatekey = var.cicd_bot_ssh_private_key
    known_hosts    = var.github_known_hosts
  }
}

resource "kubernetes_secret" "cicd_bot_container_registry_access_token" {
  type = "kubernetes.io/basic-auth"
  metadata {
    name      = "cicd-bot-container-registry-credentials"
    namespace = "tekton-pipelines"
    annotations = {
      "tekton.dev/docker-0" = "hub.docker.com"
    }
  }
  binary_data = {
    username = base64encode(var.cicd_bot_container_registry_username)
    password = base64encode(var.cicd_bot_container_registry_access_token)
  }
}

# Tekton Triggers
# Based on https://github.com/sdaschner/tekton-argocd-example/tree/main/pipelinetriggers

data "google_storage_bucket_object_content" "tekton_triggers" {
  name   = "triggers/previous/v${var.tekton_triggers_version}/release.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton_triggers" {
  content = data.google_storage_bucket_object_content.tekton_triggers.content
}

resource "kubectl_manifest" "tekton_triggers" {
  count            = length(data.kubectl_file_documents.tekton_triggers.documents)
  yaml_body        = element(data.kubectl_file_documents.tekton_triggers.documents, count.index)
  wait_for_rollout = false
}

data "google_storage_bucket_object_content" "tekton_triggers_interceptors" {
  name   = "triggers/previous/v${var.tekton_triggers_version}/interceptors.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton_triggers_interceptors" {
  content = data.google_storage_bucket_object_content.tekton_triggers_interceptors.content
}

resource "kubectl_manifest" "tekton_triggers_interceptors" {
  count            = length(data.kubectl_file_documents.tekton_triggers_interceptors.documents)
  yaml_body        = element(data.kubectl_file_documents.tekton_triggers_interceptors.documents, count.index)
  wait_for_rollout = false
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_role" "cicd_bot_role" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  metadata {
    namespace = "tekton-pipelines"
    name      = "cicd-bot-role"
  }
  # EventListeners need to be able to fetch all namespaced resources
  rule {
    api_groups = ["triggers.tekton.dev"]
    resources  = ["eventlisteners", "triggerbindings", "triggertemplates", "triggers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    # configmaps is needed for updating logging config
    resources = ["configmaps"]
    verbs     = ["get", "list", "watch"]
  }
  # Permissions to create resources in associated TriggerTemplates
  rule {
    api_groups = ["tekton.dev"]
    resources  = ["pipelineruns", "pipelineresources", "taskruns"]
    verbs      = ["create"]
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["impersonate"]
  }
  rule {
    api_groups     = ["policy"]
    resources      = ["podsecuritypolicies"]
    resource_names = ["tekton-triggers"]
    verbs          = ["use"]
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_role_binding" "tekton_triggers_role_binding" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "cicd-bot-role-binding"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = "tekton-pipelines"
    name      = "cicd-bot"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "cicd-bot-role"
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_cluster_role" "tekton_triggers_sa_cluster_role" {
  metadata {
    name = "cicd-bot-cluster-role"
  }
  rule {
    # EventListeners need to be able to fetch any clustertriggerbindings, and clusterinterceptors
    api_groups = ["triggers.tekton.dev"]
    resources  = ["clustertriggerbindings", "clusterinterceptors"]
    verbs      = ["get", "list", "watch"]
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_cluster_role_binding" "tekton_triggers_sa_cluster_role_binding" {
  metadata {
    name = "cicd-bot-cluster-role-binding"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cicd-bot"
    namespace = "tekton-pipelines"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cicd-bot-cluster-role"
  }
}

resource "random_password" "github_trigger_secret" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/secret.yaml
resource "kubernetes_secret" "github_trigger_secret" {
  type = "Opaque"
  metadata {
    name        = "github-secret"
    namespace   = "tekton-pipelines"
    annotations = {}
    labels      = {}
  }
  binary_data = {
    secretToken = base64encode(random_password.github_trigger_secret.result)
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubectl_manifest" "github_event_listener" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "EventListener"
    metadata = {
      name      = "github-event-listener"
      namespace = "tekton-pipelines"
      finalizers = [
        "eventlisteners.triggers.tekton.dev",
      ]
    }
    spec = {
      namespaceSelector  = {}
      serviceAccountName = "cicd-bot"
      triggers = [
        {
          triggerRef = "github-trigger"
        }
      ]
      resources = {
        kubernetesResource = {
          spec = {
            template = {
              spec = {
                serviceAccountName = "cicd-bot"
                containers = [
                  {
                    name = ""
                    resources = {
                      requests = {
                        memory = "64Mi"
                        # cpu    = "250m"
                      }
                      limits = {
                        memory = "128Mi"
                        # cpu    = "500m"
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }
  })
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubectl_manifest" "github_trigger" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "Trigger"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-trigger"
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
              name = "secretRef"
              value = {
                secretName = "github-secret"
                secretKey  = "secretToken"
              }
            },
            {
              name = "eventTypes"
              value = [
                "pull_request"
                # "push",
              ]
            },
          ]
        },
        {
          name = "only when PRs are opened"
          ref = {
            kind = "ClusterInterceptor"
            name = "cel"
          }
          params = [
            {
              name = "filter"
              # value = "body.ref == 'refs/heads/main'"
              value = "body.action in ['opened', 'synchronize', 'reopened']"
            }
          ]
        }
      ]
      bindings = [
        {
          kind = "TriggerBinding"
          ref  = "github-trigger-binding"
        }
      ]
      template = {
        ref = "github-trigger-template"
      }
    }
  })
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubectl_manifest" "github_trigger_binding" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerBinding"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-trigger-binding"
      # name      = "build-deploy-binding"
    }
    spec = {
      params = [
        {
          name  = "revision"
          value = "$(body.pull_request.head.sha)"
        },
        {
          name  = "url"
          value = "$(body.repository.ssh_url)"
        }
      ]
    }
  })
}

# Based on the example at https://github.com/tektoncd/triggers/blob/main/docs/triggertemplates.md
resource "kubectl_manifest" "github_trigger_template" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerTemplate"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-trigger-template"
    }
    spec = {
      params = [
        {
          name = "url"
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
            generateName = "github-pipeline-run-"
          }
          spec = {
            serviceAccountName = "cicd-bot"
            pipelineRef = {
              name = "github-pipeline"
            }
            params = [
              {
                name  = "url"
                value = "$(tt.params.url)"
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
                        storage = "1Gi"
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

# Based on the example at https://tekton.dev/vault/pipelines-v0.26.0/pipelines/#pipelines
resource "kubectl_manifest" "github_pipeline" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Pipeline"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-pipeline"
    }
    spec = {
      params = [
        {
          name        = "url"
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
          name = "git-clone"
          taskRef = {
            name = "git-clone"
          }
          workspaces = [
            {
              name      = "default" # Must match what the git-clone task expects.
              workspace = "default" # Must match above
            }
          ]
          params = [
            {
              name = "url"
              value = "$(params.url)"
            },
            {
              name = "revision"
              value = "$(params.revision)"
            }
          ]
        },
        {
          runAfter = [
            "git-clone"
          ]
          name = "check-commit"
          taskRef = {
            name = "check-commit"
          }
          workspaces = [
            {
              name      = "default"
              workspace = "default" # Must match above
            }
          ]
        }
      ]
    }
  })
}

resource "kubectl_manifest" "git_clone_task" {
  yaml_body = <<-YAML
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      namespace: tekton-pipelines
      name: git-clone
    spec:
      params:
      - name: url
        description: Repository URL to clone from.
        type: string
      - name: revision
        description: Revision to checkout. (branch, tag, sha, ref, etc...)
        type: string
      workspaces:
      - name: default
        mountPath: "/workspace"
      steps:
      - name: check-out
        image: "alpine/git:v2.32.0"
        workingDir: $(workspaces.default.path)
        env:
        - name: PARAM_URL
          value: $(params.url)
        - name: PARAM_REVISION
          value: $(params.revision)
        script: |
          #!/bin/sh
          set -eux
          pwd
          git init
          git remote add origin "$${PARAM_URL}"
          git fetch origin "$${PARAM_REVISION}" --depth=1
          git reset --hard FETCH_HEAD
          git rev-parse --verify HEAD
          ls -al
  YAML
}

resource "kubectl_manifest" "github_task" {
  yaml_body = <<-YAML
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      namespace: tekton-pipelines
      name: check-commit
    spec:
      workspaces:
      - name: default
        mountPath: "/workspace"
      steps:
      - image: "alpine/git:v2.32.0"
        workingDir: $(workspaces.default.path)
        script: |
          #!/bin/sh
          set -eux
          git rev-parse --verify HEAD
          pwd
          ls -al
  YAML
}

# Based on the example at https://github.com/tektoncd/pipeline/blob/v0.28.1/examples/v1beta1/pipelineruns/demo-optional-resources.yaml
# resource "kubectl_manifest" "github_pipeline" {
#   depends_on = [
#     kubectl_manifest.tekton_triggers,
#     kubectl_manifest.tekton_triggers_interceptors
#   ]
#   yaml_body = yamlencode({
#     apiVersion = "tekton.dev/v1beta1"
#     kind       = "Pipeline"
#     metadata = {
#       namespace = "tekton-pipelines"
#       name      = "github-pipeline"
#     }
#     spec = {
#       params = [
#         {
#           name        = "workspaceSize"
#           type        = "string"
#           description = "The size of the workspace to reserve. Deleted after pipeline run."
#           default     = "1Gi"
#         }
#       ]
#       resources = [
#         {
#           name = "source"  # Must match the name in the TriggerTemplate above.
#           type = "git"
#         }
#       ]
#       volumes = [
#         {
#           name = "docker-socket"
#           hostPath = {
#             path = "/var/run/docker.sock"
#             type = "Socket"
#           }
#         }
#       ]
#       # workspaces = [
#       #   {
#       #     name = "default-workspace"
#       #     volumeClaimTemplate = {
#       #       spec = {
#       #         accessModes = [
#       #           "ReadWriteOnce"
#       #         ]
#       #         resources = {
#       #           requests = {
#       #             storage = "$(params.workspaceSize)"
#       #           }
#       #         }
#       #       }
#       #     }
#       #   }
#       # ]
#       tasks = [
#         {
#           name = "check-commit"
#           # workspaces = [
#           #   {
#           #     name      = "default-workspace"
#           #     workspace = "default-workspace" # must match the workspace name above
#           #   }
#           # ]
#           taskSpec = {
#             metadata = {}
#             resources = {
#               inputs = [
#                 {
#                   name     = "source"
#                   resource = "source" # Must match the PipelineResource name above
#                 }
#               ]
#             }
#             steps = [
#               {
#                 image      = "ubuntu"
#                 name       = "check-commit"
#                 workingDir = "$(resources.inputs.source.path)"
#                 volumeMounts = [
#                   {
#                     name      = "docker-socket"
#                     mountPath = "/var/run/docker.sock"
#                   }
#                 ]
#                 script = <<-EOF
#                   pwd
#                   ls
#                   git rev-parse --verify --short
#                   docker ls
#                   # git init
#                   # git add remote origin $(params.url)
#                   # git checkout $(params.revision)
#                   # git reset --hard
#                 EOF
#               }
#             ]
#           }
#         }
#       ]
#     }
#   })
# }

resource "google_dns_record_set" "triggers_tekon_iskprinter_com" {
  project      = var.project
  managed_zone = var.dns_managed_zone_name
  name         = "triggers.tekton.iskprinter.com."
  type         = "A"
  rrdatas      = [var.ingress_ip]
  ttl          = 300
}

resource "kubernetes_ingress" "tekton_triggers_ingress" {
  metadata {
    name      = "tekton-triggers-ingress"
    namespace = "tekton-pipelines"
    annotations = {
      "kubernetes.io/ingress.class"              = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }
  spec {
    rule {
      host = "triggers.tekton.iskprinter.com"
      http {
        path {
          path = "/"
          backend {
            service_name = "el-github-event-listener"
            service_port = 8080
          }
        }
      }
    }
    tls {
      hosts = [
        "triggers.tekton.iskprinter.com"
      ]
      secret_name = "tls-triggers-tekton-iskprinter-com"
    }
  }
}

resource "kubectl_manifest" "certificate_triggers_tekton_iskprinter_com" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "certificate-triggers-tekton-iskprinter-com"
      namespace = "tekton-pipelines"
    }
    spec = {
      secretName = "tls-triggers-tekton-iskprinter-com"
      issuerRef = {
        # The issuer created previously
        kind = "ClusterIssuer"
        name = "lets-encrypt-prod"
      }
      dnsNames = [
        "triggers.tekton.iskprinter.com"
      ]
    }
  })
}
