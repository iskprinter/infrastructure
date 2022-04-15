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
