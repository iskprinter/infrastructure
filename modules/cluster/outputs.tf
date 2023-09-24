output "kubeconfig" {
  description = "Connect to the cluster by running $(terraform output -raw kubeconfig)"
  value       = "gcloud --project ${var.project} container clusters get-credentials --region ${var.region} ${google_container_cluster.main.name}"
}
