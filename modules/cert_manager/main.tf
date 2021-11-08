resource "google_service_account" "cert_manager" {
  project      = var.project
  account_id   = "cert-manager"
  display_name = "Certificate Manager Service Account"
}

resource "google_service_account_iam_member" "service_account_iam_workload_identity_user_binding" {
  service_account_id = google_service_account.cert_manager.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${var.namespace}/cert-manager]"
}

resource "google_project_iam_member" "service_account_dns_record_sets_binding" {
  project = var.project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cert_manager.email}"
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = var.namespace
  create_namespace = true
  set {
    name  = "installCRDs"
    value = true
  }
  set {
    name  = "prometheus.enabled"
    value = false
  }
  set {
    name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
    value = google_service_account.cert_manager.email
  }
}

# resource "kubernetes_manifest" "issuer_lets_encrypt_staging" {
resource "kubectl_manifest" "issuer_lets_encrypt_staging" {
  depends_on = [
    helm_release.cert_manager
  ]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "lets-encrypt-staging"
    }
    spec = {
      acme = {
        # The ACME server URL
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        # Email address used for ACME registration
        email = "cameronhudson8@gmail.com"
        # Name of a secret used to store the ACME account private key
        privateKeySecretRef = {
          name = "lets-encrypt-staging-private-key"
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
  })
}

# resource "kubernetes_manifest" "issuer_lets_encrypt_prod" {
resource "kubectl_manifest" "issuer_lets_encrypt_prod" {
  depends_on = [
    helm_release.cert_manager
  ]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "lets-encrypt-prod"
    }
    spec = {
      acme = {
        # The ACME server URL
        server = "https://acme-v02.api.letsencrypt.org/directory"
        # Email address used for ACME registration
        email = "cameronhudson8@gmail.com"
        # Name of a secret used to store the ACME account private key
        privateKeySecretRef = {
          name = "lets-encrypt-prod-private-key"
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
  })
}
