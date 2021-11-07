locals {
  mongodb_operator_files = [
    "${path.module}/lib/mongodb_kubernetes_operator/config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml",
    "${path.module}/lib/mongodb_kubernetes_operator/config/manager/manager.yaml",
    "${path.module}/lib/mongodb_kubernetes_operator/deploy/clusterwide/role_binding.yaml",
    "${path.module}/lib/mongodb_kubernetes_operator/deploy/clusterwide/role.yaml",
  ]
}

resource "kubernetes_namespace" "mongodb_community_operator" {
  metadata {
    name = var.namespace
  }
}

data "kubectl_file_documents" "mongodb_community_operator" {
  for_each = toset(local.mongodb_operator_files)
  content  = file(each.value)
}

resource "kubectl_manifest" "mongodb_community_operator" {
  depends_on = [
    kubernetes_namespace.mongodb_community_operator
  ]
  for_each           = merge([for file in data.kubectl_file_documents.mongodb_community_operator : file.manifests]...)
  yaml_body          = each.value
  override_namespace = var.namespace
}
