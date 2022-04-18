resource "kubectl_manifest" "api_client_credentials" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1alpha1"
    kind       = "ExternalSecret"
    type       = "Opaque"
    metadata = {
      namespace = "iskprinter"
      name      = "api-client-credentials"
    }
    spec = {
      secretStoreRef = {
        name = "hashicorp-vault-kv"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "api-client-credentials"
      }
      data = [
        {
          secretKey = "id"
          remoteRef = {
            key      = "secret/${var.env_name}/api-client-credentials"
            property = "id"
          },
        },
        {
          secretKey = "secret"
          remoteRef = {
            key      = "secret/${var.env_name}/api-client-credentials"
            property = "secret"
          }
        }
      ]
      refreshInterval = "5s"
    }
  })
}

resource "kubectl_manifest" "cicd_bot_ssh_key" {
  count = var.env_name == "prod" ? 1 : 0
  yaml_body = yamlencode({
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
  })
}

resource "kubectl_manifest" "cicd_bot_personal_access_token" {
  count = var.env_name == "prod" ? 1 : 0
  yaml_body = yamlencode({
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
  })
}

resource "kubectl_manifest" "github_webhook_secret" {
  count = var.env_name == "prod" ? 1 : 0
  yaml_body = yamlencode({
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
  })
}
