dependencies {
  paths = ["../clusters"]
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
      experiments {
        manifest_resource = true
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
      project              = "${include.env.locals.project}"
      external_dns_version = "${include.env.locals.external_dns_version}"
    }

  EOF
}
