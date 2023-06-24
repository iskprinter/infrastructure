remote_state {
  backend = "gcs"
  generate = {
    path      = "terragrunt_generated_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    project              = "cameronhudson8"
    bucket               = "iskprinter-tf-state"
    prefix               = "infrastructure/dev-${run_cmd("--terragrunt-quiet", "whoami")}/${basename(path_relative_to_include())}"
    skip_bucket_creation = true
  }
}

locals {
  kubernetes_provider         = "minikube"
  env_name                    = "dev"
  use_real_lets_encrypt_certs = false
}
