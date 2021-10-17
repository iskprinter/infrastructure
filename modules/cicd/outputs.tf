output "cicd_namespace" {
  value = "tekton-pipelines"
}

output "google_service_account_cicd_bot_email" {
  value = google_service_account.cicd_bot.email
}
