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

    module "${basename(path_relative_to_include("env"))}" {
      source             = "../../../modules/${basename(path_relative_to_include("env"))}"
      project            = "${include.env.locals.project}"
      location           = "${include.global.locals.region}-a"
      cluster_name       = "${include.env.locals.cluster_name}"
      min_node_8gb_count = "${include.env.locals.min_node_8gb_count}"
      max_node_8gb_count = "${include.env.locals.max_node_8gb_count}"
    }

  EOF
}
