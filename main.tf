terraform {
  backend "gcs" {
    bucket = "iskprinter-tf-state-prod"
    prefix = "infrastructure"
  }
}

data "google_client_config" "current" {}

module "cluster" {
  source             = "./modules/cluster/"
  project            = var.project
  location           = "${var.region}-a"
  min_node_2gb_count = var.min_node_2gb_count
  max_node_2gb_count = var.max_node_2gb_count
  min_node_4gb_count = var.min_node_4gb_count
  max_node_4gb_count = var.max_node_4gb_count
  min_node_8gb_count = var.min_node_8gb_count
  max_node_8gb_count = var.max_node_8gb_count
  access_token       = data.google_client_config.current.access_token
}

module "ingress" {
  source        = "./modules/ingress"
  nginx_version = var.nginx_version
}

module "dns" {
  source     = "./modules/dns/"
  project    = var.project
  ingress_ip = module.ingress.ip
}

module "cert_manager" {
  source               = "./modules/cert_manager/"
  project              = var.project
  cert_manager_version = var.cert_manager_version
}

module "preemption_cleanup" {
  source             = "./modules/preemption_cleanup/"
  alpine_k8s_version = var.alpine_k8s_version
}

module "cicd" {
  source                                = "./modules/cicd/"
  alpine_k8s_version                    = var.alpine_k8s_version
  api_client_credentials_secret_name    = var.api_client_credentials_secret_name
  api_client_id                         = var.api_client_id
  api_client_secret_base64              = var.api_client_secret_base64
  cicd_bot_github_username              = var.cicd_bot_github_username
  cicd_bot_name                         = var.cicd_bot_name
  cicd_bot_personal_access_token_base64 = var.cicd_bot_personal_access_token_base64
  cicd_bot_ssh_private_key_base64       = var.cicd_bot_ssh_private_key_base64
  dns_managed_zone_name                 = module.dns.managed_zone_name
  github_known_hosts_base64             = var.github_known_hosts_base64
  ingress_ip                            = module.ingress.ip
  kaniko_version                        = var.kaniko_version
  mongodb_connection_secret_name        = var.mongodb_connection_secret_name
  mongodb_connection_url                = module.database.mongodb_connection_url
  project                               = var.project
  region                                = var.region
  tekton_dashboard_version              = var.tekton_dashboard_version
  tekton_pipeline_version               = var.tekton_pipeline_version
  tekton_triggers_version               = var.tekton_triggers_version
  terraform_version                     = var.terraform_version
}

module "database" {
  source                       = "./modules/database/"
  cicd_bot_name                = var.cicd_bot_name
  cicd_namespace               = module.cicd.cicd_namespace
  neo4j_persistent_volume_size = var.neo4j_persistent_volume_size
  neo4j_version                = var.neo4j_version
  project                      = var.project
  region                       = var.region
}

module "iskprinter" {
  source                                = "./modules/iskprinter"
  api_client_credentials_secret_name    = var.api_client_credentials_secret_name
  cicd_bot_name                         = var.cicd_bot_name
  cicd_namespace                        = module.cicd.cicd_namespace
  google_service_account_cicd_bot_email = module.cicd.google_service_account_cicd_bot_email
  mongodb_connection_secret_name        = var.mongodb_connection_secret_name
  project                               = var.project
}
