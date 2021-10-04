
variable "cluster_ca_certificate" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_client_certificate" {
  type = string
}

variable "cluster_client_key" {
  type      = string
  sensitive = true
}

variable "git_bot_ssh_key_base64" {
  type      = string
  sensitive = true
}

variable "git_bot_container_registry_username" {
  type = string
}

variable "git_bot_container_registry_access_token" {
  type      = string
  sensitive = true
}

variable "ingress_ip" {
  type = string
}

variable "project" {
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
