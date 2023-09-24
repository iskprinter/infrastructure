resource "kubernetes_manifest" "cicd_bot_ssh_key" {
  manifest = {
    apiVersion = "external-secrets.io/v1alpha1"
    kind       = "ExternalSecret"
    type       = "Opaque"
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
      }
      data = [
        {
          secretKey = "ssh-privatekey"
          remoteRef = {
            key      = "secret/${var.env_name}/cicd-bot-ssh-key"
            property = "ssh-privatekey"
          }
        },
        {
          secretKey = "known_hosts"
          remoteRef = {
            key      = "secret/${var.env_name}/cicd-bot-ssh-key"
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
    apiVersion = "external-secrets.io/v1alpha1"
    kind       = "ExternalSecret"
    type       = "Opaque"
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
      }
      data = [
        {
          secretKey = "username"
          remoteRef = {
            key      = "secret/${var.env_name}/cicd-bot-personal-access-token"
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = "secret/${var.env_name}/cicd-bot-personal-access-token"
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
    apiVersion = "external-secrets.io/v1alpha1"
    kind       = "ExternalSecret"
    type       = "Opaque"
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
      }
      data = [
        {
          secretKey = "secret"
          remoteRef = {
            key      = "secret/${var.env_name}/github-webhook-secret"
            property = "secret"
          }
        }
      ]
      refreshInterval = "5s"
    }
  }
}
