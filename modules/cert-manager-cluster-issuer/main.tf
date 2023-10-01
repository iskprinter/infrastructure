resource "kubernetes_manifest" "issuer_lets_encrypt" {
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
