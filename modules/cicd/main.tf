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

# SSH Key
resource "kubernetes_manifest" "git_bot_ssh_key" {
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    type       = "kubernetes.io/ssh-auth"
    metadata = {
      name      = "git-ssh-key"
      namespace = "tekton-pipelines"
      annotations = {
        "tekton.dev/git-0" = "github.com"
      }
    }
    data = {
      ssh-privatekey = var.git_ssh_key_base64
    }
  }
}
