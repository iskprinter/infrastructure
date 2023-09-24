remote_state {
  backend = "gcs"
  generate = {
    path      = "terragrunt_generated_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    project              = "cameronhudson8"
    bucket               = "iskprinter-tf-state"
    prefix               = "infrastructure/prod/${basename(path_relative_to_include())}.tfstate"
    skip_bucket_creation = true
  }
}

locals {
  kubernetes_provider         = "gcp"
  env_name                    = "prod"
  project                     = "cameronhudson8"
  cluster_name                = "general-purpose-cluster"
  machine_type                = "e2-highmem-2"
  min_node_count              = 1
  max_node_count              = 2
  region                      = "us-west1"
  tekton_pipeline_version     = "0.52.0"
  tekton_triggers_version     = "0.25.0"
  tekton_dashboard_version    = "0.39.0"
  ingress_nginx_version       = "4.7.0" # The helm chart version
  external_dns_version        = "0.7.6" # The helm chart version
  terraform_version           = "1.0.11"
  kaniko_version              = "1.8.1"
  alpine_k8s_version          = "1.20.7"
  use_real_lets_encrypt_certs = true
}
