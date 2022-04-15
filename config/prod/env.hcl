remote_state {
  backend = "gcs"
  generate = {
    path      = "terragrunt_generated_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    project              = "cameronhudson8"
    location             = "us-west1"
    bucket               = "iskprinter-tf-state"
    prefix               = "infrastructure/prod/${basename(path_relative_to_include())}.tfstate"
    skip_bucket_creation = true
  }
}

locals {
  kubernetes_provider                   = "gcp"
  project                               = "cameronhudson8"
  region                                = "us-west1"
  cluster_name                          = "general-purpose-cluster"
  min_node_8gb_count                    = 1
  max_node_8gb_count                    = 3
  cert_manager_gcp_service_account_name = "cert-manager"
}
