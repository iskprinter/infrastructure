variable "project" {
  type = string
}

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

variable "cert_manager_version" {
  type = string
}
