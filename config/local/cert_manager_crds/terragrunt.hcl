include "global" {
  path           = "../../global.hcl"
  merge_strategy = "deep"
  expose         = true
}

include "env" {
  path           = "../env.hcl"
  merge_strategy = "deep"
  expose         = true
}

generate "providers" {
  path      = "terragrunt_generated_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<-EOF

    provider "helm" {
      kubernetes {
      config_path = "~/.kube/config"
      config_context = "minikube"
      }
    }

  EOF

}

generate "modules" {
  path      = "terragrunt_generated_modules.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<-EOF

    module "${basename(path_relative_to_include("env"))}" {
      source               = "../../../modules/${basename(path_relative_to_include("env"))}"
      cert_manager_version = "${include.global.locals.cert_manager_version}"
      kubernetes_provider  = "${include.env.locals.kubernetes_provider}"
    }

  EOF
}