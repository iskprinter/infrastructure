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

generate "modules" {
  path      = "terragrunt_generated_modules.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<-EOF

    module "${replace(basename(path_relative_to_include("env")), "-", "_")}" {
      source                                       = "../../../modules/${basename(path_relative_to_include("env"))}"
      project                                      = "${include.env.locals.project}"
      cert_manager_gcp_service_account_name        = "${include.env.locals.cert_manager_gcp_service_account_name}"
      cert_manager_operator_namespace              = "${include.global.locals.cert_manager_operator_namespace}"
      cert_manager_kubernetes_service_account_name = "${include.global.locals.cert_manager_kubernetes_service_account_name}"
    }

  EOF
}
