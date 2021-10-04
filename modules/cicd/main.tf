provider "kubectl" {
  host                   = "https://${var.cluster_endpoint}"
  client_certificate     = var.cluster_client_certificate
  client_key             = var.cluster_client_key
  cluster_ca_certificate = var.cluster_ca_certificate
}

provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  client_certificate     = var.cluster_client_certificate
  client_key             = var.cluster_client_key
  cluster_ca_certificate = var.cluster_ca_certificate
  experiments {
    manifest_resource = true
  }
}

# DNS zone

resource "google_dns_managed_zone" "tekton" {
  project     = var.project
  name        = "tekton-iskprinter-com"
  dns_name    = "tekton.iskprinter.com."
  description = "Managed zone for tekton.iskprinter.com hosts"
}

resource "google_dns_record_set" "tekton_iskprinter_com" {
  project      = var.project
  managed_zone = google_dns_managed_zone.tekton.name
  name         = "tekton.iskprinter.com."
  type         = "A"
  rrdatas      = [var.ingress_ip]
  ttl          = 300
}

resource "google_dns_record_set" "wildcard_tekon_iskprinter_com" {
  project      = var.project
  managed_zone = google_dns_managed_zone.tekton.name
  name         = "triggers.tekton.iskprinter.com."
  type         = "A"
  rrdatas      = [var.ingress_ip]
  ttl          = 300
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

resource "kubernetes_manifest" "tekton_dashboard_ingress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1beta1"
    kind       = "Ingress"
    metadata = {
      name      = "tekton-dashboard-ingress"
      namespace = "tekton-pipelines"
      annotations = {
        "kubernetes.io/ingress.class" = "nginx"
        "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
      }
    }
    spec = {
      rules = [
        {
          host = "dashboard.tekton.iskprinter.com"
          http = {
            paths = [
              {
                path = "/"
                backend = {
                  serviceName = "tekton-dashboard"
                  servicePort = 9097
                }
              }
            ]
          }
        }
      ]
      tls = [
        {
          hosts = [
            "dashboard.tekton.iskprinter.com"
          ]
          secretName = "tls-iskprinter-com"
        }
      ]
    }
  }
}

# Service account and credentials
# Based on https://github.com/sdaschner/tekton-argocd-example

resource "kubernetes_manifest" "git_bot_ssh_key" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    type       = "kubernetes.io/ssh-auth"
    metadata = {
      name      = "git-bot-ssh-key"
      namespace = "tekton-pipelines"
      annotations = {
        "tekton.dev/git-0" = "github.com"
      }
    }
    data = {
      ssh-privatekey = var.git_bot_ssh_key_base64
    }
  }
}

resource "kubernetes_manifest" "git_bot_container_registry_access_token" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    type       = "kubernetes.io/basic-auth"
    metadata = {
      name      = "git-bot-container-registry-credentials"
      namespace = "tekton-pipelines"
      annotations = {
        "tekton.dev/docker-0" = "hub.docker.com"
      }
    }
    data = {
      username = base64encode(var.git_bot_container_registry_username)
      password = base64encode(var.git_bot_container_registry_access_token)
    }
  }
}

resource "kubernetes_manifest" "git_bot_service_account" {
  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = "git-bot"
      namespace = "tekton-pipelines"
    }
    secrets = [
      {
        name = "git-bot-container-registry-credentials"
      },
      {
        name = "git-bot-ssh-key"
      },
      {}
    ]
  }
  computed_fields = [
    "secrets[2]"
  ]
}

resource "kubernetes_manifest" "git_bot_role" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "Role"
    metadata = {
      name      = "git-bot-role"
      namespace = "tekton-pipelines"
    }
    rules = [
      {
        apiGroups = ["serving.knative.dev"]
        resources = ["*"]
        verbs     = ["*"]
      },
      {
        apiGroups = ["eventing.knative.dev"]
        resources = ["*"]
        verbs     = ["*"]
      },
      {
        apiGroups = ["sources.eventing.knative.dev"]
        resources = ["*"]
        verbs     = ["*"]
      },
      {
        apiGroups = [""]
        resources = [
          "pods",
          "services",
          "endpoints",
          "configmaps",
          "secrets",
        ]
        verbs = ["*"]
      },
      {
        apiGroups = ["apps"]
        resources = [
          "deployments",
          "daemonsets",
          "replicasets",
          "statefulsets",
        ]
        verbs = ["*"]
      },
      {
        apiGroups = [""]
        resources = ["pods"]
        verbs     = ["get"]
      },
      {
        apiGroups = ["apps"]
        resources = [
          "replicasets"
        ]
        verbs = [
          "get"
        ]
      }
    ]
  }
}

resource "kubernetes_manifest" "git_bot_role_binding" {

  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "RoleBinding"
    metadata = {
      name      = "git-bot-role-binding"
      namespace = "tekton-pipelines"
    }
    roleRef = {
      kind     = "Role"
      name     = "git-bot-role"
      apiGroup = "rbac.authorization.k8s.io"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "git-bot"
        namespace = "tekton-pipelines"
      }
    ]
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

resource "kubernetes_manifest" "tekon_trigger_service_account" {
  manifest = {
    kind       = "ServiceAccount"
    apiVersion = "v1"
    metadata = {
      name      = "tekton-github-triggers"
      namespace = "tekton-pipelines"
    }
    secrets = [
      {
        name = "github-trigger-secret"
      },
      {}
    ]
  }
  computed_fields = ["secrets[1]"]
}

resource "kubernetes_manifest" "tekon_trigger_role" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  manifest = {
    kind       = "Role"
    apiVersion = "rbac.authorization.k8s.io/v1"
    metadata = {
      name      = "tekton-github-triggers"
      namespace = "tekton-pipelines"
    }
    rules = [
      {
        # Permissions for every EventListener deployment to function
        apiGroups = ["triggers.tekton.dev"]
        resources = ["eventlisteners", "triggerbindings", "triggertemplates", "triggers"]
        verbs     = ["get", "list", "watch"]
      },
      {
        # secrets are only needed for Github/Gitlab interceptors, serviceaccounts only for per trigger authorization
        apiGroups = [""]
        resources = ["configmaps", "secrets", "serviceaccounts"]
        verbs     = ["get", "list", "watch"]
      },
      {
        # Permissions to create resources in associated TriggerTemplates
        apiGroups = ["tekton.dev"]
        resources = ["pipelineruns", "pipelineresources", "taskruns"]
        verbs     = ["create"]
      }
    ]
  }
}

resource "kubernetes_manifest" "tekon_trigger_role_binding" {
  manifest = {
    kind       = "RoleBinding"
    apiVersion = "rbac.authorization.k8s.io/v1"
    metadata = {
      name      = "tekton-triggers-github-binding"
      namespace = "tekton-pipelines"
    }
    subjects = [
      {
        kind = "ServiceAccount"
        name = "tekton-github-triggers"
      }
    ]
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "Role"
      name     = "tekton-github-triggers"
    }
  }
}


resource "kubernetes_manifest" "tekon_trigger_cluster_role" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  manifest = {
    kind       = "ClusterRole"
    apiVersion = "rbac.authorization.k8s.io/v1"
    metadata = {
      name = "tekton-github-triggers"
    }
    rules = [
      {
        # EventListeners need to be able to fetch any clustertriggerbindings
        apiGroups = ["triggers.tekton.dev"]
        resources = ["clustertriggerbindings"]
        verbs     = ["get", "list", "watch"]
      }
    ]
  }
}

resource "kubernetes_manifest" "tekon_trigger_cluster_role_binding" {
  manifest = {


    kind       = "ClusterRoleBinding"
    apiVersion = "rbac.authorization.k8s.io/v1"
    metadata = {
      name = "tekton-triggers-example-clusterbinding"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "tekton-github-triggers"
        namespace = "tekton-pipelines"
      }
    ]
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "tekton-github-triggers"
    }
  }
}

resource "random_password" "github_trigger_secret" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "kubernetes_manifest" "github_trigger_secret" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    type       = "Opaque"
    metadata = {
      name      = "github-trigger-secret"
      namespace = "tekton-pipelines"
    }
    data = {
      secretToken = base64encode(random_password.github_trigger_secret.result)
    }
  }
}

resource "kubernetes_manifest" "trigger_template_build_deploy" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1alpha1"
    kind       = "TriggerTemplate"
    metadata = {
      name      = "build-deploy-template"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "buildRevision"
          description = "The Git commit revision"
        }
      ]
      resourcetemplates = [
        {
          apiVersion = "tekton.dev/v1beta1"
          kind       = "PipelineRun"
          metadata = {
            generateName = "build-deploy-"
          }
          spec = {
            pipelineRef = {
              name = "build-deploy"
            }
            serviceAccountName = "git-bot"
            params = [
              {
                name  = "buildRevision"
                value = "$(tt.params.buildRevision)"
              },
              {
                name  = "appGitUrl"
                value = "git@github.com:example/app.git"
              },
              {
                name  = "configGitUrl"
                value = "git@github.com:example/app-config.git"
              },
              {
                name  = "appImage"
                value = "docker.example.com/app"
              }
            ]
            workspaces = [
              {
                name     = "app-source"
                emptyDir = {}
              },
              {
                name     = "config-source"
                emptyDir = {}
              }
            ]
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "trigger_binding_build_deploy" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1alpha1"
    kind       = "TriggerBinding"
    metadata = {
      name      = "build-deploy-binding"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name  = "buildRevision"
          value = "$(body.head_commit.id)"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "github_trigger_event_listener" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  manifest = {
    apiVersion = "triggers.tekton.dev/v1alpha1"
    kind       = "EventListener"
    metadata = {
      name      = "github-listener-interceptor"
      namespace = "tekton-pipelines"
      finalizers = [
        "eventlisteners.triggers.tekton.dev",
      ]
    }
    spec = {
      namespaceSelector  = {}
      resources          = {}
      serviceAccountName = "tekton-github-triggers"
      triggers = [
        {
          name = "github-listener"
          bindings = [
            {
              kind = "TriggerBinding"
              ref  = "build-deploy-binding"
            },
          ]
          interceptors = [
            {
              params = [
                {
                  name = "secretRef"
                  value = {
                    secretKey  = "secretToken"
                    secretName = "github-trigger-secret"
                  }
                },
                {
                  name = "eventTypes"
                  value = [
                    "push",
                  ]
                },
              ]
              ref = {
                kind = "ClusterInterceptor"
                name = "github"
              }
            },
            {
              params = [
                {
                  name  = "filter"
                  value = "body.ref == 'refs/heads/main'"
                }
              ]
              ref = {
                kind = "ClusterInterceptor"
                name = "cel"
              }
            }
          ]
          template = {
            ref = "build-deploy-template"
          }
        }
      ]
    }
  }
}
