dependencies {
  paths = ["../cluster"]
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

    data "google_container_cluster" "general_purpose" {
      project  = "${include.env.locals.project}"
      location = "${include.env.locals.region}-a"
      name     = "${include.env.locals.cluster_name}"
    }

    provider "helm" {
      kubernetes {
        host                   = "https://$${data.google_container_cluster.general_purpose.endpoint}"
        token                  = data.google_client_config.provider.access_token
        cluster_ca_certificate = base64decode(data.google_container_cluster.general_purpose.master_auth[0].cluster_ca_certificate)
      }
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
  contents  = <<-EOF

    module "${replace(basename(path_relative_to_include("env")), "-", "_")}" {
      source                        = "../../../modules/${basename(path_relative_to_include("env"))}"
      cert_manager_operator_version = "${include.global.locals.cert_manager_operator_version}"
      kubernetes_provider           = "${include.env.locals.kubernetes_provider}"
      project                       = "${include.env.locals.project}"
      use_real_lets_encrypt_certs   = ${include.env.locals.use_real_lets_encrypt_certs}
    }

  EOF
}
