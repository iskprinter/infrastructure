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

# resource "kubernetes_manifest" "certificate_dashboard_tekton_iskprinter_com" {
resource "kubectl_manifest" "certificate_dashboard_tekton_iskprinter_com" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "certificate-dashboard-tekton-iskprinter-com"
      namespace = "tekton-pipelines"
    }
    spec = {
      secretName = "tls-dashboard-tekton-iskprinter-com"
      issuerRef = {
        # The issuer created previously
        kind = "ClusterIssuer"
        name = "lets-encrypt-prod"
      }
      dnsNames = [
        "dashboard.tekton.iskprinter.com"
      ]
    }
  })
}

resource "kubernetes_ingress" "tekton_dashboard_ingress" {
  metadata {
    name      = "tekton-dashboard-ingress"
    namespace = "tekton-pipelines"
    annotations = {
      "kubernetes.io/ingress.class"              = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }
  spec {
    rule {
      host = "dashboard.tekton.iskprinter.com"
      http {
        path {
          path = "/"
          backend {
            service_name = "tekton-dashboard"
            service_port = 9097
          }
        }
      }
    }
    tls {
      hosts = [
        "dashboard.tekton.iskprinter.com"
      ]
      secret_name = "tls-dashboard-tekton-iskprinter-com"
    }
  }
}

# Service account and credentials
# Based on https://github.com/sdaschner/tekton-argocd-example

resource "kubernetes_secret" "git_bot_ssh_key" {
  type = "kubernetes.io/ssh-auth"
  metadata {
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

resource "kubernetes_secret" "git_bot_container_registry_access_token" {
  type = "kubernetes.io/basic-auth"
  metadata {
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

resource "kubernetes_service_account" "git_bot_service_account" {
  metadata {
    name      = "git-bot"
    namespace = "tekton-pipelines"
  }
  secret {
    name = "git-bot-container-registry-credentials"
  }
  secret {
    name = "git-bot-ssh-key"
  }
}

resource "kubernetes_role" "git_bot_role" {
  metadata {
    name      = "git-bot-role"
    namespace = "tekton-pipelines"
  }
  rule {
    api_groups = ["serving.knative.dev"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  rule {
    api_groups = ["eventing.knative.dev"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  rule {
    api_groups = ["sources.eventing.knative.dev"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  rule {
    api_groups = [""]
    resources = [
      "pods",
      "services",
      "endpoints",
      "configmaps",
      "secrets",
    ]
    verbs = ["*"]
  }
  rule {
    api_groups = ["apps"]
    resources = [
      "deployments",
      "daemonsets",
      "replicasets",
      "statefulsets",
    ]
    verbs = ["*"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get"]
  }
  rule {
    api_groups = ["apps"]
    resources = [
      "replicasets"
    ]
    verbs = [
      "get"
    ]
  }
}

resource "kubernetes_role_binding" "git_bot_role_binding" {
  metadata {
    name      = "git-bot-role-binding"
    namespace = "tekton-pipelines"
  }
  role_ref {
    kind      = "Role"
    name      = "git-bot-role"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "git-bot"
    namespace = "tekton-pipelines"
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

resource "kubernetes_service_account" "tekon_trigger_service_account" {
  metadata {
    name      = "tekton-github-triggers"
    namespace = "tekton-pipelines"
  }
  secret {
    name = "github-trigger-secret"
  }
}

resource "kubernetes_role" "tekon_trigger_role" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  metadata {
    name      = "tekton-github-triggers"
    namespace = "tekton-pipelines"
  }
  rule {
    # Permissions for every EventListener deployment to function
    api_groups = ["triggers.tekton.dev"]
    resources  = ["eventlisteners", "triggerbindings", "triggertemplates", "triggers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    # secrets are only needed for Github/Gitlab interceptors, serviceaccounts only for per trigger authorization
    api_groups = [""]
    resources  = ["configmaps", "secrets", "serviceaccounts"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    # Permissions to create resources in associated TriggerTemplates
    api_groups = ["tekton.dev"]
    resources  = ["pipelineruns", "pipelineresources", "taskruns"]
    verbs      = ["create"]
  }
}

resource "kubernetes_role_binding" "tekon_trigger_role_binding" {
  metadata {
    name      = "tekton-triggers-github-binding"
    namespace = "tekton-pipelines"
  }
  subject {
    kind = "ServiceAccount"
    name = "tekton-github-triggers"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "tekton-github-triggers"
  }
}

resource "kubernetes_cluster_role" "tekon_trigger_cluster_role" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  metadata {
    name = "tekton-github-triggers"
  }
  rule {
    # EventListeners need to be able to fetch any clustertriggerbindings
    api_groups = ["triggers.tekton.dev"]
    resources  = ["clustertriggerbindings"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "tekon_trigger_cluster_role_binding" {
  metadata {
    name        = "tekton-triggers-example-clusterbinding"
    annotations = {}
    labels      = {}
  }
  subject {
    kind      = "ServiceAccount"
    name      = "tekton-github-triggers"
    namespace = "tekton-pipelines"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "tekton-github-triggers"
  }
}

resource "random_password" "github_trigger_secret" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "kubernetes_secret" "github_trigger_secret" {
  type = "Opaque"
  metadata {
    name        = "github-trigger-secret"
    namespace   = "tekton-pipelines"
    annotations = {}
    labels      = {}
  }
  data = {
    secretToken = base64encode(random_password.github_trigger_secret.result)
  }
}

resource "kubernetes_manifest" "trigger_template_build_deploy" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
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
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
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
