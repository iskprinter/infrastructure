
# GCP Environment

variable "project" {
  type    = string
  default = "cameronhudson8"
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "min_node_2gb_count" {
  type    = number
  default = 0
}

variable "max_node_2gb_count" {
  type    = number
  default = 2
}

variable "min_node_4gb_count" {
  type    = number
  default = 0
}

variable "max_node_4gb_count" {
  type    = number
  default = 2
}

variable "min_node_8gb_count" {
  type    = number
  default = 0
}

variable "max_node_8gb_count" {
  type    = number
  default = 2
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

variable "alpine_k8s_version" {
  type    = string
  default = "1.20.7"
}

variable "api_client_id" {
  type    = string
  default = "bf9674bde4cd432193ac5644daf38b07"
}

variable "api_client_secret_base64" {
  type      = string
  sensitive = true
}

variable "cicd_bot_github_username" {
  type    = string
  default = "IskprinterGitBot"
}

variable "cicd_bot_name" {
  type    = string
  default = "cicd-bot"
}

variable "cicd_bot_personal_access_token_base64" {
  type      = string
  sensitive = true
}

variable "cicd_bot_ssh_private_key_base64" {
  type      = string
  sensitive = true
}

variable "github_known_hosts_base64" {
  type = string
}

variable "kaniko_version" {
  type    = string
  default = "1.3.0"
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

variable "terraform_version" {
  type    = string
  default = "1.0.9"
}

# Certificates

variable "cert_manager_version" {
  type    = string
  default = "1.5.0"
}

# Iskprinter Namespace

variable "api_client_credentials_secret_name" {
  type    = string
  default = "api-client-credentials"
}

variable "mongodb_connection_secret_name" {
  type    = string
  default = "mongodb-connection"
}
