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
      source  = "../../../modules/${basename(path_relative_to_include("env"))}"
      project = "${include.env.locals.project}"
      region  = "${include.env.locals.region}"
    }

  EOF
}
