output "mongodb_connection_url" {
  value     = "mongodb+srv://${urlencode(local.admin_username)}:${urlencode(random_password.mongodb.result)}@${local.release}-svc.${local.namespace}.svc.cluster.local/?ssl=false"
  sensitive = true
}
