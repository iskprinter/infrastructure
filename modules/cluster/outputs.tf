output "kubeconfig" {
  description = "Connect to the cluster by running $(terraform output -raw kubeconfig)"
  value       = "gcloud --project ${var.project} container clusters get-credentials --zone ${var.location} ${google_container_cluster.general_purpose.name}"
}
