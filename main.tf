terraform {
  backend "gcs" {
    bucket = "iskprinter-terraform-state"
  }
}

module "cluster" {
  source         = "./modules/cluster/"
  project        = var.project
  location       = "${var.region}-a"
  min_node_count = var.min_node_count
  max_node_count = var.max_node_count
}

module "database" {
  source                       = "./modules/database/"
  project                      = var.project
  region                       = var.region
  cluster_endpoint             = module.cluster.cluster_endpoint
  cluster_client_certificate   = module.cluster.cluster_client_certificate
  cluster_client_key           = module.cluster.cluster_client_key
  cluster_ca_certificate       = module.cluster.cluster_ca_certificate
  neo4j_version                = var.neo4j_version
  neo4j_persistent_volume_size = var.neo4j_persistent_volume_size
}

module "ingress" {
  source                     = "./modules/ingress"
  cluster_endpoint           = module.cluster.cluster_endpoint
  cluster_client_certificate = module.cluster.cluster_client_certificate
  cluster_client_key         = module.cluster.cluster_client_key
  cluster_ca_certificate     = module.cluster.cluster_ca_certificate
  nginx_version              = var.nginx_version
}

module "dns" {
  source     = "./modules/dns/"
  project    = var.project
  ingress_ip = module.ingress.ip
}

module "cicd" {
  source                                  = "./modules/cicd/"
  cluster_endpoint                        = module.cluster.cluster_endpoint
  cluster_client_certificate              = module.cluster.cluster_client_certificate
  cluster_client_key                      = module.cluster.cluster_client_key
  cluster_ca_certificate                  = module.cluster.cluster_ca_certificate
  git_bot_ssh_key_base64                  = var.git_bot_ssh_key_base64
  git_bot_container_registry_username     = var.git_bot_container_registry_username
  git_bot_container_registry_access_token = var.git_bot_container_registry_access_token
  tekton_pipeline_version                 = var.tekton_pipeline_version
  tekton_triggers_version                 = var.tekton_triggers_version
}
