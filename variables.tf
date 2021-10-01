
# GCP Environment
variable "project" {
  type    = string
  default = "cameronhudson8"
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "min_node_count" {
  type    = number
  default = 2
}

variable "max_node_count" {
  type    = number
  default = 4
}

# Ingress

variable "nginx_version" {
  type    = string
  default = "0.10.1" # The helm chart version. Corresponds to Nginx 1.12.1.
}

# Database


variable "neo4j_version" {
  type    = string
  default = "4.3.4" # The Neo4j version.
}

variable "neo4j_persistent_volume_size" {
  type    = string
  default = "32Gi"
}

# CI/CD

variable "tekton_pipeline_version" {
  type    = string
  default = "0.28.0"
}

variable "tekton_triggers_version" {
  type    = string
  default = "0.15.2"
}

variable "tekton_dashboard_version" {
  type = string
  default = "0.20.0"
}

variable "git_bot_ssh_key_base64" {
  type      = string
  sensitive = true
}

variable "git_bot_container_registry_username" {
  type = string
  default = "iskprintergitbot"
}

variable "git_bot_container_registry_access_token" {
  type      = string
  sensitive = true
}
