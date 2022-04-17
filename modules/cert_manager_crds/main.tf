resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = "cert-manager"
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
