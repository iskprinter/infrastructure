dependencies {
  paths = [
    "../cluster",
    "../tekton-pipeline-crds",
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
  contents  = <<-EOF

    data "google_client_config" "provider" {}

    data "google_container_cluster" "main" {
      project  = "${include.env.locals.project}"
      location = "${include.env.locals.region}"
      name     = "${include.env.locals.cluster_name}"
    }

    provider "kubernetes" {
      host                   = "https://$${data.google_container_cluster.main.endpoint}"
      token                  = data.google_client_config.provider.access_token
      cluster_ca_certificate = base64decode(data.google_container_cluster.main.master_auth[0].cluster_ca_certificate) 
    }

  EOF
}

generate "modules" {
  path      = "terragrunt_generated_modules.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF

    module "${replace(basename(path_relative_to_include("env")), "-", "_")}" {
      source                  = "../../../modules/${basename(path_relative_to_include("env"))}"
      tekton_triggers_version = "${include.env.locals.tekton_triggers_version}"
    }

  EOF
}
