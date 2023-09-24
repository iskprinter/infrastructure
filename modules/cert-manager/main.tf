locals {
  cert_manager_kubernetes_service_account_name = "cert-manager"
  cert_manager_operator_namespace              = "cert-manager"
}

resource "google_service_account" "cert_manager" {
  count        = (var.kubernetes_provider == "gcp" ? 1 : 0)
  project      = var.project
  account_id   = "cert-manager"
  display_name = "Certificate Manager Service Account"
}

resource "google_service_account_iam_member" "service_account_iam_workload_identity_user_binding" {
  count              = (var.kubernetes_provider == "gcp" ? 1 : 0)
  service_account_id = google_service_account.cert_manager[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${local.cert_manager_operator_namespace}/${local.cert_manager_kubernetes_service_account_name}]"
}

resource "google_project_iam_member" "service_account_dns_record_sets_binding" {
  count   = (var.kubernetes_provider == "gcp" ? 1 : 0)
  project = var.project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cert_manager[0].email}"
}

resource "helm_release" "cert_manager_operator" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_operator_version
  namespace        = local.cert_manager_operator_namespace
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
      value = "${google_service_account.cert_manager[0].name}@${var.project}.iam.gserviceaccount.com"
    }
  }
}

resource "kubernetes_manifest" "issuer_lets_encrypt" {
  depends_on = [
    helm_release.cert_manager_operator
  ]
  count = (var.use_real_lets_encrypt_certs ? 1 : 0)
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "lets-encrypt"
    }
    spec = {
      acme = {
        # The ACME server URL
        server = "https://acme-v02.api.letsencrypt.org/directory"
        # Email address used for ACME registration
        email = "cameronhudson8@gmail.com"
        # Name of a secret used to store the ACME account private key
        privateKeySecretRef = {
          name = "lets-encrypt-private-key"
        }
        # Enable the DNS-01 challenge provider
        solvers = [
          {
            dns01 = {
              cloudDNS = {
                project = var.project
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "issuer_self_signed" {
  depends_on = [
    helm_release.cert_manager_operator
  ]
  count = (var.use_real_lets_encrypt_certs ? 0 : 1)
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "self-signed"
    }
    spec = {
      selfSigned = {}
    }
  }
}
