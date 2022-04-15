variable "cert_manager_version" {
  type = string
}

variable "kubernetes_provider" {
  type = string
}

variable "cert_manager_gcp_service_account_name" {
  default = "N/A"
  type    = string
}

variable "project" {
  default = "N/A"
  type    = string
}
