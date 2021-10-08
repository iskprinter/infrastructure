variable "alpine_k8s_version" {
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
