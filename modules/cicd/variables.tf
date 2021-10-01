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

variable "cluster_ca_certificate" {
  type = string
}

variable "tekton_pipeline_version" {
  type = string
}

variable "tekton_triggers_version" {
  type = string
}

variable "git_user" {
  type = string
}

variable "git_ssh_key_base64" {
  type      = string
  sensitive = true
}
