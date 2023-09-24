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
  contents  = <<-EOF

    module "${replace(basename(path_relative_to_include("env")), "-", "_")}" {
      source                     = "../../../modules/${basename(path_relative_to_include("env"))}"
      project                    = "${include.env.locals.project}"
      region                     = "${include.env.locals.region}"
      cluster_name               = "${include.env.locals.cluster_name}"
      kubernetes_release_channel = "${include.env.locals.kubernetes_release_channel}"
      machine_type               = "${include.env.locals.machine_type}"
      min_node_count             = "${include.env.locals.min_node_count}"
      max_node_count             = "${include.env.locals.max_node_count}"
    }

  EOF
}
