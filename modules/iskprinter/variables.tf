variable "api_client_id" {
  type = string
}

variable "api_client_secret_base64" {
  type      = string
  sensitive = true
}

variable "cicd_bot_name" {
  type = string
}

variable "cicd_namespace" {
  type = string
}

variable "google_service_account_cicd_bot_email" {
  type = string
}

variable "project" {
  type = string
}
