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

# Tekton Triggers

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

# Tekton Triggers Interceptors

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

# Use a kubectl_manifest for this because kubernetes_manifest has an issue with the automatic service account token
resource "kubectl_manifest" "git_bot_service_account" {
  yaml_body = <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: git-bot
  namespace: tekton-pipelines
secrets:
- name: git-bot-container-registry-credentials
- name: git-bot-ssh-key
EOF
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
