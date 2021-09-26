provider "kubectl" {
  host                   = "https://${var.cluster_endpoint}"
  client_certificate     = var.cluster_client_certificate
  client_key             = var.cluster_client_key
  cluster_ca_certificate = var.cluster_ca_certificate
}

data "google_storage_bucket_object_content" "tekton" {
  name   = "pipeline/previous/v${var.tekton_version}/release.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton" {
  content = data.google_storage_bucket_object_content.tekton.content
}

resource "kubectl_manifest" "tekton" {
  count     = length(data.kubectl_file_documents.tekton.documents)
  yaml_body = element(data.kubectl_file_documents.tekton.documents, count.index)
}
