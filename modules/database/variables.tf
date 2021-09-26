variable "project" {
  type = string
}

variable "region" {
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

variable "cluster_ca_certificate" {
  type = string
}

variable "neo4j_version" {
  type = string
}

variable "neo4j_persistent_volume_size" {
  type = string
}
