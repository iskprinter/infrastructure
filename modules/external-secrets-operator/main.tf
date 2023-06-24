resource "helm_release" "external_secrets_operator" {
  name             = "external-secrets-operator"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_version
  namespace        = "external-secrets-operator"
  create_namespace = true
  set {
    name = "installCRDs"
    value = true
  }
}
