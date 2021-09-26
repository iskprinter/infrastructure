output "kubeconfig" {
  description = "Connect to the cluster by running $(terraform output -raw kubeconfig)"
  value       = "gcloud --project ${var.project} container clusters get-credentials --zone ${var.location} ${google_container_cluster.general_purpose.name}"
}

output "cluster_endpoint" {
  value = google_container_cluster.general_purpose.endpoint
}

output "cluster_client_certificate" {
  value = base64decode(google_container_cluster.general_purpose.master_auth[0].client_certificate)
}

output "cluster_client_key" {
  value     = base64decode(google_container_cluster.general_purpose.master_auth[0].client_key)
  sensitive = true
}

output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.general_purpose.master_auth[0].cluster_ca_certificate)
}
