resource "helm_release" "mongodb_operator" {
  name             = "mongodb-operator"
  repository       = "https://mongodb.github.io/helm-charts"
  chart            = "community-operator"
  version          = var.mongodb_operator_version
  namespace        = "mongodb-operator"
  create_namespace = true
  set {
    name  = "installCRDs"
    value = true
  }
  set {
    name  = "operator.watchNamespace"
    value = "*"
  }
}
