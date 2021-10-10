
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

# Cleanup

variable "alpine_k8s_version" {
  type    = string
  default = "1.20.7"
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

variable "cicd_bot_ssh_private_key_base_64" {
  type      = string
  sensitive = true
}

# variable "cicd_bot_container_registry_username" {
#   type    = string
#   default = "iskprintergitbot"
# }

# variable "cicd_bot_container_registry_access_token" {
#   type      = string
#   sensitive = true
# }

variable "github_known_hosts_base_64" {
  type = string
}

variable "tekton_pipeline_version" {
  type    = string
  default = "0.28.1"
}

variable "tekton_triggers_version" {
  type    = string
  default = "0.15.2"
}

variable "tekton_dashboard_version" {
  type    = string
  default = "0.20.0"
}

# Certificates

variable "cert_manager_version" {
  type    = string
  default = "1.5.0"
}
