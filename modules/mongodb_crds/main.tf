locals {
  mongodb_operator_files = [
    "${path.module}/lib/mongodb_kubernetes_operator/config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml",
    "${path.module}/lib/mongodb_kubernetes_operator/config/manager/manager.yaml",
    "${path.module}/lib/mongodb_kubernetes_operator/config/rbac/role.yaml",
    "${path.module}/lib/mongodb_kubernetes_operator/config/rbac/role_binding.yaml",
    "${path.module}/lib/mongodb_kubernetes_operator/config/rbac/service_account.yaml",
    "${path.module}/lib/mongodb_kubernetes_operator/deploy/clusterwide/role.yaml",
    "${path.module}/lib/mongodb_kubernetes_operator/deploy/clusterwide/role_binding.yaml",
  ]
}

resource "kubernetes_namespace" "mongodb_operator" {
  metadata {
    name = "mongodb-operator"
  }
}

data "kubectl_file_documents" "mongodb_community_operator" {
  for_each = toset(local.mongodb_operator_files)
  content  = file(each.value)
}

resource "kubectl_manifest" "mongodb_community_operator" {
  for_each           = merge([for file in data.kubectl_file_documents.mongodb_community_operator : file.manifests]...)
  yaml_body          = each.value
  override_namespace = kubernetes_namespace.mongodb_operator.metadata[0].name
}
