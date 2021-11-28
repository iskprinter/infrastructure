locals {
  cicd_bot_personal_access_token_key = "password"
}

# Image Registry

resource "google_artifact_registry_repository" "iskprinter" {
  provider      = google-beta
  project       = var.project
  repository_id = "iskprinter"
  location      = var.region
  format        = "DOCKER"
}

# Tekton Pipeline

data "google_storage_bucket_object_content" "tekton_pipeline" {
  name   = "pipeline/previous/v${var.tekton_pipeline_version}/release.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton_pipeline" {
  content = data.google_storage_bucket_object_content.tekton_pipeline.content
}

resource "kubectl_manifest" "tekton_pipeline" {
  for_each         = data.kubectl_file_documents.tekton_pipeline.manifests
  yaml_body        = each.value
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
  for_each         = data.kubectl_file_documents.tekton_dashboard.manifests
  yaml_body        = each.value
  wait_for_rollout = false
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
  for_each         = data.kubectl_file_documents.tekton_triggers.manifests
  yaml_body        = each.value
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
  for_each         = data.kubectl_file_documents.tekton_triggers_interceptors.manifests
  yaml_body        = each.value
  wait_for_rollout = false
}

# Service account and credentials

resource "google_service_account" "cicd_bot" {
  project      = var.project
  account_id   = "cicd-bot"
  display_name = "CICD Bot Service Account"
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
    ssh-privatekey = var.cicd_bot_ssh_private_key_base64
    known_hosts    = var.github_known_hosts_base64
  }
}

resource "kubernetes_service_account" "cicd_bot" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "cicd-bot"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.cicd_bot.email
    }
  }
  secret {
    name = kubernetes_secret.cicd_bot_ssh_key.metadata[0].name
  }
}

resource "google_service_account_iam_member" "cicd_bot_iam_workload_identity_user_binding" {
  service_account_id = google_service_account.cicd_bot.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${kubernetes_service_account.cicd_bot.metadata[0].namespace}/${kubernetes_service_account.cicd_bot.metadata[0].name}]"
}

resource "google_project_iam_custom_role" "cicd_bot_role" {
  project = var.project
  role_id = "cicd_bot"
  title   = "CICD Bot"
  permissions = [
    "artifactregistry.repositories.downloadArtifacts",
    "artifactregistry.repositories.uploadArtifacts",
    "compute.instanceGroupManagers.get",
    "container.clusters.get",
    "container.cronJobs.create",
    "container.cronJobs.delete",
    "container.cronJobs.get",
    "container.cronJobs.update",
    "container.customResourceDefinitions.create",
    "container.customResourceDefinitions.delete",
    "container.customResourceDefinitions.get",
    "container.customResourceDefinitions.update",
    "container.deployments.create",
    "container.deployments.delete",
    "container.deployments.get",
    "container.deployments.update",
    "container.ingresses.create",
    "container.ingresses.delete",
    "container.ingresses.get",
    "container.ingresses.update",
    "container.jobs.create",
    "container.jobs.delete",
    "container.jobs.get",
    "container.jobs.update",
    "container.namespaces.get",
    "container.persistentVolumeClaims.create",
    "container.persistentVolumeClaims.delete",
    "container.persistentVolumeClaims.get",
    "container.persistentVolumeClaims.update",
    "container.roleBindings.create",
    "container.roleBindings.delete",
    "container.roleBindings.get",
    "container.roleBindings.update",
    "container.roles.create",
    "container.roles.delete",
    "container.roles.get",
    "container.roles.update",
    "container.secrets.create",
    "container.secrets.delete",
    "container.secrets.get",
    "container.secrets.list",
    "container.secrets.update",
    "container.serviceAccounts.create",
    "container.serviceAccounts.delete",
    "container.serviceAccounts.get",
    "container.serviceAccounts.update",
    "container.services.create",
    "container.services.delete",
    "container.services.get",
    "container.services.update",
    "container.thirdPartyObjects.create",
    "container.thirdPartyObjects.delete",
    "container.thirdPartyObjects.get",
    "container.thirdPartyObjects.update",
    "dns.changes.create",
    "dns.changes.get",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list",
    "dns.resourceRecordSets.update",
    "storage.buckets.get",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
  ]
}

resource "google_project_iam_member" "cicd_bot_storage_admin_binding" {
  project = var.project
  role    = google_project_iam_custom_role.cicd_bot_role.name
  member  = "serviceAccount:${google_service_account.cicd_bot.email}"
}

resource "kubernetes_secret" "cicd_bot_personal_access_token" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "cicd-bot-personal-access-token"
  }
  binary_data = {
    username                                   = base64encode(var.cicd_bot_github_username)
    (local.cicd_bot_personal_access_token_key) = var.cicd_bot_personal_access_token_base64
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_role" "tekton_triggers" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  metadata {
    namespace = "tekton-pipelines"
    name      = "tekton-triggers"
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
resource "kubernetes_role_binding" "tekton_triggers" {
  metadata {
    namespace = kubernetes_role.tekton_triggers.metadata[0].namespace
    name      = "tekton-triggers"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account.cicd_bot.metadata[0].namespace
    name      = kubernetes_service_account.cicd_bot.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.tekton_triggers.metadata[0].name
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.1/examples/rbac.yaml
resource "kubernetes_cluster_role" "tekton_triggers" {
  metadata {
    name = "tekton-triggers"
  }
  rule {
    # EventListeners need to be able to fetch any clustertriggerbindings, and clusterinterceptors
    api_groups = ["triggers.tekton.dev"]
    resources  = ["clustertriggerbindings", "clusterinterceptors"]
    verbs      = ["get", "list", "watch"]
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_cluster_role_binding" "tekton_triggers" {
  metadata {
    name = "tekton-triggers"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account.cicd_bot.metadata[0].namespace
    name      = kubernetes_service_account.cicd_bot.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.tekton_triggers.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "cicd_bot" {
  metadata {
    name = "cicd-bot"
  }
  # EventListeners need to be able to fetch all namespaced resources
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get"]
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_cluster_role_binding" "cicd_bot" {
  metadata {
    name = "cicd-bot"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account.cicd_bot.metadata[0].namespace
    name      = kubernetes_service_account.cicd_bot.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cicd_bot.metadata[0].name
  }
}

resource "random_password" "secret_github_webhook" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/secret.yaml
resource "kubernetes_secret" "secret_github_webhook" {
  type = "Opaque"
  metadata {
    name        = "github-webhook"
    namespace   = "tekton-pipelines"
    annotations = {}
    labels      = {}
  }
  binary_data = {
    secretToken = base64encode(random_password.secret_github_webhook.result)
  }
}

# Routing

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
            service_name = "el-github"
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

# Event Listeners

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubectl_manifest" "event_listener_github" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "EventListener"
    metadata = {
      name      = "github"
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
          triggerRef = "github-image-pr"
        },
        {
          triggerRef = "github-release-pr"
        },
        {
          triggerRef = "github-release-push"
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
                      limits = {
                        memory = "64Mi"
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
                secretName = "github-webhook"
                secretKey  = "secretToken"
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
                secretName = "github-webhook"
                secretKey  = "secretToken"
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
              value = "(requestURL.parseURL().path == \"/github/release\") && (body.action in ['opened', 'synchronize', 'reopened'])"
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
                secretName = "github-webhook"
                secretKey  = "secretToken"
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
              value = "(requestURL.parseURL().path == \"/github/release\") && (body.action in ['closed'])"
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
                secretName = "github-webhook"
                secretKey  = "secretToken"
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
              value = "(requestURL.parseURL().path == \"/github/release\") && (body.ref == \"refs/heads/main\")"
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

# TriggerBindings

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubectl_manifest" "trigger_binding_github_pr" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerBinding"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-pr"
    }
    spec = {
      params = [
        {
          name  = "github-status-url"
          value = "$(body.pull_request.statuses_url)"
        },
        {
          name  = "pr-number"
          value = "$(body.number)"
        },
        {
          name  = "repo-name"
          value = "$(body.repository.name)"
        },
        {
          name  = "repo-url"
          value = "$(body.repository.ssh_url)"
        }
      ]
    }
  })
}

resource "kubectl_manifest" "trigger_binding_github_push" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerBinding"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-push"
    }
    spec = {
      params = [
        {
          name  = "repo-name"
          value = "$(body.repository.name)"
        },
        {
          name  = "repo-url"
          value = "$(body.repository.ssh_url)"
        },
        {
          name  = "revision"
          value = "$(body.head_commit.id)"
        }
      ]
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
            serviceAccountName = "cicd-bot"
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
            serviceAccountName = "cicd-bot"
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
            serviceAccountName = "cicd-bot"
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
            serviceAccountName = "cicd-bot"
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
              value = local.cicd_bot_personal_access_token_key
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
              value = local.cicd_bot_personal_access_token_key
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

# Tasks

resource "kubectl_manifest" "task_report_status" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "report-status"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "github-status-url"
          description = "The GitHub status URL"
        },
        {
          name        = "github-token"
          description = "The GitHub personal access token of the CICD bot"
        },
        {
          name        = "github-username"
          description = "The GitHub username of the CICD bot"
        },
        {
          name        = "tekton-pipeline-status"
          description = "The Tekton pipeline status"
        }
      ]
      steps = [
        {
          image = "alpine:3.14"
          name  = "report-status"
          env = [
            {
              name  = "GITHUB_STATUS_URL"
              value = "$(params.github-status-url)"
            },
            {
              name  = "GITHUB_TOKEN"
              value = "$(params.github-token)"
            },
            {
              name  = "GITHUB_USERNAME"
              value = "$(params.github-username)"
            },
            {
              name  = "TEKTON_PIPELINE_STATUS"
              value = "$(params.tekton-pipeline-status)"
            }
          ]
          command = ["/bin/sh"]
          args = [
            "-c",
            file("${path.module}/report_status.sh")
          ]
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_get_secret" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "get-secret"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "secret-key"
          description = "The key of the secret to fetch"
        },
        {
          name        = "secret-name"
          description = "The name of the secret to fetch"
        },
        {
          name        = "secret-namespace"
          description = "The namespace of the secret to fetch"
        }
      ]
      results = [
        {
          name        = "secret-value"
          description = "The value of the secret"
        }
      ]
      steps = [
        {
          image = "alpine/k8s:${var.alpine_k8s_version}"
          name  = "get-secret"
          env = [
            {
              name  = "SECRET_KEY"
              value = "$(params.secret-key)"
            },
            {
              name  = "SECRET_NAME"
              value = "$(params.secret-name)"
            },
            {
              name  = "SECRET_NAMESPACE"
              value = "$(params.secret-namespace)"
            }
          ]
          script = <<-EOF
            #!/bin/bash
            set -euxo pipefail
            secret_value=$(
                kubectl get secret "$SECRET_NAME" \
                    -n "$SECRET_NAMESPACE" \
                    -o jsonpath="{.data.$${SECRET_KEY}}" \
                | base64 -d
            )
            set +x
            echo -n "$secret_value" > $(results.secret-value.path)
            set -x
            EOF
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_github_get_pr_sha" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      "namespace" = "tekton-pipelines"
      "name"      = "github-get-pr-sha"
    }
    spec = {
      params = [
        {
          name        = "github-token"
          description = "The GitHub personal access token of the CICD bot"
        },
        {
          name        = "github-username"
          description = "The GitHub username of the CICD bot"
        },
        {
          name        = "pr-number"
          description = "PR number to check out."
          type        = "string"
        },
        {
          name        = "repo-name"
          description = "The name of the repository for which to find the PR SHA."
          type        = "string"
        }
      ]
      results = [
        {
          name        = "revision"
          description = "The git commit hash"
        }
      ]
      steps = [
        {
          name  = "github-get-pr-sha"
          image = "alpine:3.14"
          env = [
            {
              name  = "GITHUB_USERNAME"
              value = "$(params.github-username)"
            },
            {
              name  = "GITHUB_TOKEN"
              value = "$(params.github-token)"
            },
            {
              name  = "PR_NUMBER"
              value = "$(params.pr-number)"
            },
            {
              name  = "REPO_NAME"
              value = "$(params.repo-name)"
            }
          ]
          script = <<-EOF
            #!/bin/sh
            set -eux
            TIMEOUT_SECONDS=30
            apk update
            apk add --no-cache \
                curl \
                jq
            pr_response=''
            mergeable=''
            i=0
            while [ $i -lt $TIMEOUT_SECONDS ]; do
                echo '---'
                echo "$i"
                pr_response=$(
                    curl \
                        -X GET \
                        -u "$${GITHUB_USERNAME}:$${GITHUB_TOKEN}" \
                        -H 'Accept: application/vnd.github.v3+json' \
                        "https://api.github.com/repos/iskprinter/$${REPO_NAME}/pulls/$${PR_NUMBER}"
                )
                mergeable=$(echo "$pr_response" | jq -r '.mergeable')
                if [ "$mergeable" = 'true' ]; then
                    break;
                fi
                sleep 1
                i=$(expr $i + 1)
            done
            if [ $i -gte 30 ]; then
                echo "Unable to get merge commit from GitHub within $${TIMEOUT_SECONDS}. 'mergeable' status was $${mergeable}." >2
            fi
            merge_commit_sha=$(echo "$pr_response" | jq -r '.merge_commit_sha')
            echo -n "$merge_commit_sha" | tee $(results.revision.path)
            EOF
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_github_checkout_commit" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      "namespace" = "tekton-pipelines"
      "name"      = "github-checkout-commit"
    }
    spec = {
      params = [
        {
          name        = "repo-url"
          description = "Repository URL to clone from."
          type        = "string"
        },
        {
          name        = "revision"
          description = "Revision to checkout. (branch, tag, sha, ref, etc...)"
          type        = "string"
        }
      ]
      "workspaces" = [
        {
          name      = "default"
          mountPath = "/workspace"
        }
      ]
      steps = [
        {
          name       = "github-checkout"
          image      = "alpine/git:v2.32.0"
          workingDir = "$(workspaces.default.path)"
          env = [
            {
              name  = "REPO_URL"
              value = "$(params.repo-url)"
            },
            {
              name  = "REVISION"
              value = "$(params.revision)"
            }
          ]
          script = <<-EOF
            #!/bin/sh
            set -eux
            git init
            git remote add origin "$${REPO_URL}"
            git fetch origin "$${REVISION}" --depth=1
            git reset --hard FETCH_HEAD
            EOF
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_build_and_push_image" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "build-and-push-image"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          description = "The name of the image to build"
          name        = "image-name"
        },
        {
          description = "The tag of the image to build"
          name        = "image-tag"
        }
      ]
      steps = [
        {
          name = "build-and-push-image"
          env = [
            {
              name  = "IMAGE_NAME"
              value = "$(params.image-name)"
            },
            {
              name  = "IMAGE_TAG"
              value = "$(params.image-tag)"
            }
          ]
          image      = "gcr.io/kaniko-project/executor:${var.kaniko_version}"
          workingDir = "$(workspaces.default.path)"
          args = [
            "--destination=${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.iskprinter.name}/$(IMAGE_NAME):$(IMAGE_TAG)",
            "--cache=true"
          ]
          resources = {
            limits = {
              memory = "2Gi"
            }
          }
        }
      ]
      workspaces = [
        {
          mountPath = "/workspace"
          name      = "default"
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_terragrunt_plan" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "terragrunt-plan"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "api-client-id"
          description = "The client ID of the Eve Application"
          type        = "string"
        },
        {
          name        = "api-client-secret"
          description = "The client secret of the Eve Application"
          type        = "string"
        }
      ]
      steps = [
        {
          name = "terragrunt-plan"
          env = [
            {
              name  = "TF_VAR_api_client_id"
              value = "$(params.api-client-id)"
            },
            {
              name  = "TF_VAR_api_client_secret"
              value = "$(params.api-client-secret)"
            },
            {
              name  = "TF_VAR_api_client_credentials_secret_key_id"
              value = "${var.api_client_credentials_secret_key_id}"
            },
            {
              name  = "TF_VAR_api_client_credentials_secret_key_secret"
              value = "${var.api_client_credentials_secret_key_secret}"
            },
            {
              name  = "TF_VAR_api_client_credentials_secret_name"
              value = "${var.api_client_credentials_secret_name}"
            },
            {
              name  = "TF_VAR_api_client_credentials_secret_namespace"
              value = "${var.api_client_credentials_secret_namespace}"
            },
          ]
          image      = "alpine/terragrunt:${var.terraform_version}"
          workingDir = "$(workspaces.default.path)"
          script     = <<-EOF
            #!/bin/sh
            set -eux
            terragrunt plan --terragrunt-working-dir ./config/prod
            EOF
        }
      ]
      workspaces = [
        {
          mountPath = "/workspace"
          name      = "default"
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_terragrunt_apply" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "terragrunt-apply"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "api-client-id"
          description = "The client ID of the Eve Application"
          type        = "string"
        },
        {
          name        = "api-client-secret"
          description = "The client secret of the Eve Application"
          type        = "string"
        }
      ]
      steps = [
        {
          name = "terragrunt-apply"
          env = [
            {
              name  = "TF_VAR_api_client_id"
              value = "$(params.api-client-id)"
            },
            {
              name  = "TF_VAR_api_client_secret"
              value = "$(params.api-client-secret)"
            },
            {
              name  = "TF_VAR_api_client_credentials_secret_key_id"
              value = "${var.api_client_credentials_secret_key_id}"
            },
            {
              name  = "TF_VAR_api_client_credentials_secret_key_secret"
              value = "${var.api_client_credentials_secret_key_secret}"
            },
            {
              name  = "TF_VAR_api_client_credentials_secret_name"
              value = "${var.api_client_credentials_secret_name}"
            },
            {
              name  = "TF_VAR_api_client_credentials_secret_namespace"
              value = "${var.api_client_credentials_secret_namespace}"
            },
          ]
          image      = "alpine/terragrunt:${var.terraform_version}"
          workingDir = "$(workspaces.default.path)"
          script     = <<-EOF
            #!/bin/sh
            set -eux
            if ! terragrunt apply -auto-approve -backup=./backup.tfstate --terragrunt-non-interactive --terragrunt-working-dir ./config/prod; then
              echo 'Reverting to prior state' >2
              terragrunt apply -auto-approve -state=./backup.tfstate --terragrunt-non-interactive --terragrunt-working-dir ./config/prod
              exit 1
            fi
            EOF
        }
      ]
      workspaces = [
        {
          mountPath = "/workspace"
          name      = "default"
        }
      ]
    }
  })
}

# Cleanup (tekton does not clean up task pods or workspace PVCs)

resource "kubernetes_service_account" "tekton_cleanup" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "tekton-cleanup"
  }
}

resource "kubernetes_role" "tekton_cleanup_role" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "tekton-cleanup"
  }
  rule {
    api_groups = ["tekton.dev"]
    resources  = ["pipelineruns"]
    verbs      = ["list"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "persistentvolumeclaims"]
    verbs      = ["get", "list", "delete", "deletecollection"]
  }
}

resource "kubernetes_role_binding" "tekton_cleanup_role_binding" {
  metadata {
    name      = "tekton-cleanup"
    namespace = "tekton-pipelines"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "tekton-cleanup"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "tekton-cleanup"
    namespace = "tekton-pipelines"
  }
}

resource "kubernetes_cron_job" "tekton_cleanup" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "tekton-cleanup"
  }
  spec {
    concurrency_policy = "Replace"
    schedule           = "*/5 * * * *"
    job_template {
      metadata {
        name = "tekton-cleanup"
      }
      spec {
        template {
          metadata {
            name = "tekton-cleanup"
          }
          spec {
            service_account_name = "tekton-cleanup"
            container {
              name    = "tekton-cleanup"
              image   = "alpine/k8s:${var.alpine_k8s_version}"
              command = ["/bin/bash"]
              args = [
                "-c",
                file("${path.module}/cleanup.sh")
              ]
            }
          }
        }
      }
    }
  }
}
