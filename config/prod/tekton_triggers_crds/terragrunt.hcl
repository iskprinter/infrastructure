dependencies {
  paths = [
    "../clusters",
    "../tekton_pipeline_crds",
  ]
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
      required_version = ">= 0.13"
      required_providers {
        kubectl = {
          source  = "gavinbunney/kubectl"
          version = ">= 1.7.0"
        }
      }
    }

    data "google_client_config" "provider" {}

    data "google_container_cluster" "general_purpose" {
      project  = "${include.env.locals.project}"
      location = "${include.env.locals.region}-a"
      name     = "${include.env.locals.cluster_name}"
    }

    provider "kubectl" {
      host                   = "https://$${data.google_container_cluster.general_purpose.endpoint}"
      token                  = data.google_client_config.provider.access_token
      cluster_ca_certificate = base64decode(data.google_container_cluster.general_purpose.master_auth[0].cluster_ca_certificate) 
      load_config_file       = false
    }

  EOF

}

generate "modules" {
  path      = "terragrunt_generated_modules.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<-EOF

    module "${basename(path_relative_to_include("env"))}" {
      source                  = "../../../modules/${basename(path_relative_to_include("env"))}"
      tekton_triggers_version = "${include.env.locals.tekton_triggers_version}"
    }

  EOF
}
