dependencies {
  paths = ["../cert-manager-operator"]
}

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
      required_providers {
        kubectl = {
          source = "gavinbunney/kubectl"
        }
      }
    }

    provider "kubectl" {
      config_path    = "~/.kube/config"
      config_context = "minikube"
    }

  EOF
}

generate "modules" {
  path      = "terragrunt_generated_modules.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<-EOF

    module "${replace(basename(path_relative_to_include("env")), "-", "_")}" {
      source                      = "../../../modules/${basename(path_relative_to_include("env"))}"
      use_real_lets_encrypt_certs = ${include.env.locals.use_real_lets_encrypt_certs}
    }

  EOF
}
