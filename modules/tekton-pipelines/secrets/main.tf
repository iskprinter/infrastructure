resource "kubernetes_manifest" "cicd_bot_ssh_key" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "cicd-bot-ssh-key"
      annotations = {
        "tekton.dev/git-0" = "github.com"
      }
    }
    spec = {
      secretStoreRef = {
        name = "hashicorp-vault-kv"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "cicd-bot-ssh-key"
        template = {
          type = "kubernetes.io/ssh-auth"
        }
      }
      data = [
        {
          secretKey = "ssh-privatekey"
          remoteRef = {
            key      = "secret/cicd-bot-ssh-key"
            property = "ssh-privatekey"
          }
        },
        {
          secretKey = "known_hosts"
          remoteRef = {
            key      = "secret/cicd-bot-ssh-key"
            property = "known_hosts"
          }
        }
      ]
      refreshInterval = "5s"
    }
  }
}

resource "kubernetes_manifest" "cicd_bot_personal_access_token" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "cicd-bot-personal-access-token"
    }
    spec = {
      secretStoreRef = {
        name = "hashicorp-vault-kv"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "cicd-bot-personal-access-token"
        template = {
          type = "Opaque"
        }
      }
      data = [
        {
          secretKey = "username"
          remoteRef = {
            key      = "secret/cicd-bot-personal-access-token"
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = "secret/cicd-bot-personal-access-token"
            property = "password"
          }
        }
      ]
      refreshInterval = "5s"
    }
  }
}

resource "kubernetes_manifest" "github_webhook_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-webhook-secret"
    }
    spec = {
      secretStoreRef = {
        name = "hashicorp-vault-kv"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "github-webhook-secret"
        template = {
          type = "Opaque"
        }
      }
      data = [
        {
          secretKey = "secret"
          remoteRef = {
            key      = "secret/github-webhook-secret"
            property = "secret"
          }
        }
      ]
      refreshInterval = "5s"
    }
  }
}
