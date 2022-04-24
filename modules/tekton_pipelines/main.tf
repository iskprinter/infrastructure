module "event_listeners" {
  source        = "./event_listeners"
  cicd_bot_name = var.cicd_bot_name
}

module "pipelines" {
  source = "./pipelines"
}

module "tasks" {
  source             = "./tasks"
  project            = var.project
  region             = var.region
  alpine_k8s_version = var.alpine_k8s_version
  kaniko_version     = var.kaniko_version
  terraform_version  = var.terraform_version
}

module "trigger_bindings" {
  source = "./trigger_bindings"
}

module "trigger_templates" {
  source        = "./trigger_templates"
  cicd_bot_name = var.cicd_bot_name
}

module "triggers" {
  source = "./triggers"
}
