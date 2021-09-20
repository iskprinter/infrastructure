variable "project" {
  type    = string
  default = "cameronhudson8"
}

variable "location" {
  type    = string
  default = "us-west1-a"
}

variable "min_node_count" {
  type = number
  default = 2
}

variable "max_node_count" {
  type = number
  default = 4
}

variable "nginx_version" {
  type    = string
  default = "0.10.1"  # The helm chart version. Corresponds to Nginx 1.12.1.
}

# // ----------------------------------------------------------------------------
# // Required Variables
# // ----------------------------------------------------------------------------
# variable "gcp_project" {
#   description = "The name of the GCP project to use"
#   type        = string
#   default     = "cameronhudson8"
# }

# // ----------------------------------------------------------------------------
# // Optional Variables
# // ----------------------------------------------------------------------------
# variable "cluster_name" {
#   description = "Name of the Kubernetes cluster to create"
#   type        = string
#   default     = "iskprinter"
# }

# variable "cluster_location" {
#   description = "The location (region or zone) in which the cluster master will be created. If you specify a zone (such as us-central1-a), the cluster will be a zonal cluster with a single cluster master. If you specify a region (such as us-west1), the cluster will be a regional cluster with multiple masters spread across zones in the region"
#   type        = string
#   default     = "us-west1-a"
# }

# // ----------------------------------------------------------------------------
# // cluster configuration
# // ----------------------------------------------------------------------------
# variable "node_machine_type" {
#   description = "Node type for the Kubernetes cluster"
#   type        = string
#   default     = "e2-standard-2"
# }

# variable "min_node_count" {
#   description = "Minimum number of cluster nodes"
#   type        = number
#   default     = 2
# }

# variable "max_node_count" {
#   description = "Maximum number of cluster nodes"
#   type        = number
#   default     = 5
# }

# variable "node_disk_size" {
#   description = "Node disk size in GB"
#   type        = string
#   default     = "100"
# }

# variable "node_disk_type" {
#   description = "Node disk type, either pd-standard or pd-ssd"
#   type        = string
#   default     = "pd-standard"
# }

# // ----------------------------------------------------------------------------
# // Ingress
# // ----------------------------------------------------------------------------
# variable "apex_domain" {
#   description = "The apex / parent domain to be allocated to the cluster"
#   type        = string
#   default     = "iskprinter.com"
# }

# variable "tls_email" {
#   description = "Email used by Let's Encrypt. Required for TLS when parent_domain is specified"
#   type        = string
#   default     = "CameronHudson8@gmail.com"
# }

# variable "jx_git_url" {
#   description = "URL for the Jenkins X cluster git repository"
#   type        = string
#   default     = "https://github.com/iskprinter/cluster"
# }

# variable "jx_bot_username" {
#   description = "Bot username used to interact with the Jenkins X cluster git repository"
#   type        = string
#   default     = "IskprinterGitBot"
# }

# variable "jx_bot_token" {
#   description = "Bot token used to interact with the Jenkins X cluster git repository"
#   type        = string
# }
