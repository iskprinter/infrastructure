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

variable "nginx_version" {
  type = string
}
