output "api_client_credentials_secret_namespace" {
  value = kubernetes_secret.api_client_credentials.metadata[0].namespace
}

output "api_client_credentials_secret_name" {
  value = kubernetes_secret.api_client_credentials.metadata[0].name
}

output "api_client_credentials_secret_key_id" {
  value = local.api_client_credentials_secret_key_id
}

output "api_client_credentials_secret_key_secret" {
  value = local.api_client_credentials_secret_key_secret
}
