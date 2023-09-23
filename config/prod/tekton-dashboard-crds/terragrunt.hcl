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
  contents = <<-EOF

    data "google_client_config" "provider" {}

    data "google_container_cluster" "general_purpose" {
      project  = "${include.env.locals.project}"
      location = "${include.env.locals.region}-a"
      name     = "${include.env.locals.cluster_name}"
    }

    provider "kubernetes" {
      host                   = "https://$${data.google_container_cluster.general_purpose.endpoint}"
      token                  = data.google_client_config.provider.access_token
      cluster_ca_certificate = base64decode(data.google_container_cluster.general_purpose.master_auth[0].cluster_ca_certificate) 
    }

  EOF
}

generate "modules" {
  path      = "terragrunt_generated_modules.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<-EOF

    module "${replace(basename(path_relative_to_include("env")), "-", "_")}" {
      source                   = "../../../modules/${basename(path_relative_to_include("env"))}"
      tekton_dashboard_version = "${include.env.locals.tekton_dashboard_version}"
    }

  EOF
}