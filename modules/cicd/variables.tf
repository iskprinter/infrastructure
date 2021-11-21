variable "alpine_k8s_version" {
  type = string
}

variable "api_client_credentials_secret_key_id" {
  type = string
}

variable "api_client_credentials_secret_key_secret" {
  type = string
}

variable "api_client_credentials_secret_name" {
  type = string
}

variable "api_client_credentials_secret_namespace" {
  type = string
}

variable "cicd_bot_github_username" {
  type = string
}

variable "cicd_bot_personal_access_token_base64" {
  type      = string
  sensitive = true
}

variable "cicd_bot_ssh_private_key_base64" {
  type      = string
  sensitive = true
}

variable "dns_managed_zone_name" {
  type = string
}

variable "cicd_bot_name" {
  type = string
}

variable "github_known_hosts_base64" {
  type = string
}

variable "ingress_ip" {
  type = string
}

variable "kaniko_version" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "tekton_dashboard_version" {
  type = string
}

variable "tekton_pipeline_version" {
  type = string
}

variable "tekton_triggers_version" {
  type = string
}

variable "terraform_version" {
  type = string
}
