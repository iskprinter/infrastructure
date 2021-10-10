variable "alpine_k8s_version" {
  type = string
}

variable "cicd_bot_ssh_private_key_base_64" {
  type      = string
  sensitive = true
}

# variable "cicd_bot_container_registry_username" {
#   type = string
# }

# variable "cicd_bot_container_registry_access_token" {
#   type      = string
#   sensitive = true
# }

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

variable "dns_managed_zone_name" {
  type = string
}

variable "github_known_hosts_base_64" {
  type = string
}

variable "ingress_ip" {
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
