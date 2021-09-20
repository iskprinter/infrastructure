terraform {
  backend "gcs" {
    bucket = "iskprinter-terraform-state"
  }
}

module "cluster" {
  source   = "./modules/cluster/"
  project  = var.project
  location = var.location
  min_node_count = var.min_node_count
  max_node_count = var.max_node_count
}

# module "ingress" {
#   source                     = "./modules/ingress"
#   cluster_endpoint           = module.cluster.cluster_endpoint
#   cluster_client_certificate = module.cluster.cluster_client_certificate
#   cluster_client_key         = module.cluster.cluster_client_key
#   cluster_ca_certificate     = module.cluster.cluster_ca_certificate
#   nginx_version              = var.nginx_version
# }

module "dns" {
  source          = "./modules/dns/"
  project         = var.project
  # loadbalancer_ip = module.ingress.
}
