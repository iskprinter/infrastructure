terraform {
  backend "gcs" {
    bucket = "iskprinter-terraform-state"
  }
}

data "google_client_config" "current" {}

module "cluster" {
  source         = "./modules/cluster/"
  project        = var.project
  location       = "${var.region}-a"
  min_node_count = var.min_node_count
  max_node_count = var.max_node_count
  access_token   = data.google_client_config.current.access_token
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

module "cert_manager" {
  source                     = "./modules/cert_manager/"
  project                    = var.project
  cluster_ca_certificate     = module.cluster.cluster_ca_certificate
  cluster_client_certificate = module.cluster.cluster_client_certificate
  cluster_client_key         = module.cluster.cluster_client_key
  cluster_endpoint           = module.cluster.cluster_endpoint
  cert_manager_version       = var.cert_manager_version
}

module "preemption_cleanup" {
  source                     = "./modules/preemption_cleanup/"
  alpine_k8s_version         = var.alpine_k8s_version
  cluster_ca_certificate     = module.cluster.cluster_ca_certificate
  cluster_client_certificate = module.cluster.cluster_client_certificate
  cluster_client_key         = module.cluster.cluster_client_key
  cluster_endpoint           = module.cluster.cluster_endpoint
}

module "cicd" {
  depends_on = [
    module.cert_manager
  ]
  source                                   = "./modules/cicd/"
  alpine_k8s_version                       = var.alpine_k8s_version
  cicd_bot_container_registry_access_token = var.cicd_bot_container_registry_access_token
  cicd_bot_container_registry_username     = var.cicd_bot_container_registry_username
  cicd_bot_ssh_private_key                 = var.cicd_bot_ssh_private_key
  cluster_ca_certificate                   = module.cluster.cluster_ca_certificate
  cluster_client_certificate               = module.cluster.cluster_client_certificate
  cluster_client_key                       = module.cluster.cluster_client_key
  cluster_endpoint                         = module.cluster.cluster_endpoint
  dns_managed_zone_name                    = module.dns.managed_zone_name
  github_known_hosts                       = var.github_known_hosts
  ingress_ip                               = module.ingress.ip
  project                                  = var.project
  tekton_dashboard_version                 = var.tekton_dashboard_version
  tekton_pipeline_version                  = var.tekton_pipeline_version
  tekton_triggers_version                  = var.tekton_triggers_version
}

module "database" {
  source                       = "./modules/database/"
  cluster_ca_certificate       = module.cluster.cluster_ca_certificate
  cluster_client_certificate   = module.cluster.cluster_client_certificate
  cluster_client_key           = module.cluster.cluster_client_key
  cluster_endpoint             = module.cluster.cluster_endpoint
  neo4j_persistent_volume_size = var.neo4j_persistent_volume_size
  neo4j_version                = var.neo4j_version
  project                      = var.project
  region                       = var.region
}
