resource "helm_release" "cert_manager_operator" {
  name             = "cert-manager-operator"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_operator_version
  namespace        = var.cert_manager_operator_namespace
  create_namespace = true
  set {
    name  = "installCRDs"
    value = true
  }
  set {
    name  = "prometheus.enabled"
    value = false
  }
  dynamic "set" {
    for_each = (var.kubernetes_provider == "gcp" ? toset([{}]) : toset([]))
    content {
      name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
      value = "${var.cert_manager_gcp_service_account_name}@${var.project}.iam.gserviceaccount.com"
    }
  }
}

