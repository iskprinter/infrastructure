

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

    terraform {
      required_version = ">= 0.13"
      required_providers {
        kubectl = {
          source  = "gavinbunney/kubectl"
          version = ">= 1.7.0"
        }
      }
    }

    provider "kubectl" {
      config_path = "~/.kube/config"
      config_context = "minikube"
    }

    provider "kubernetes" {
      config_path = "~/.kube/config"
      config_context = "minikube"
    }

  EOF

}

generate "modules" {
  path      = "terragrunt_generated_modules.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<-EOF

    module "${basename(path_relative_to_include("env"))}" {
      source = "../../../modules/${basename(path_relative_to_include("env"))}"
    }

  EOF
}
