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
  domain_name                 = "iskprinter.com"
  kubernetes_provider         = "gcp"
  env_name                    = "prod"
  project                     = "cameronhudson8"
  cluster_name                = "main"
  machine_type                = "t2a-standard-1"
  min_node_count              = 1
  max_node_count              = 3
  kubernetes_release_channel  = "REGULAR"
  region                      = "us-central1"
  tekton_pipeline_version     = "0.52.0"
  tekton_triggers_version     = "0.25.0"
  tekton_dashboard_version    = "0.39.0"
  ingress_nginx_version       = "4.8.0" # The helm chart version from https://github.com/kubernetes/ingress-nginx/releases
  external_dns_version        = "0.13.5" # The container image version https://github.com/kubernetes-sigs/external-dns/releases
  terraform_version           = "1.5.7" # The container image version from https://hub.docker.com/r/alpine/terragrunt/tags
  kaniko_version              = "1.15.0" # The container image version from https://github.com/GoogleContainerTools/kaniko/releases/tag/v1.15.0
  alpine_k8s_version          = "1.25.14" # The container image version from https://hub.docker.com/r/alpine/k8s/tags
  use_real_lets_encrypt_certs = true
}
