terraform {
  backend "gcs" {
    bucket = "iskprinter-terraform-state"
  }
}

module "infrastructure" {
  source                          = "./modules/gcp/"
  gcp_project                     = var.gcp_project
  gsm                             = var.gsm
  cluster_name                    = var.cluster_name
  cluster_location                = var.cluster_location
  resource_labels                 = var.resource_labels
  node_machine_type               = var.node_machine_type
  min_node_count                  = var.min_node_count
  max_node_count                  = var.max_node_count
  node_disk_size                  = var.node_disk_size
  node_disk_type                  = var.node_disk_type
  tls_email                       = var.tls_email
  lets_encrypt_production         = var.lets_encrypt_production
  jx_git_url                      = var.jx_git_url
  jx_bot_username                 = var.jx_bot_username
  jx_bot_token                    = var.jx_bot_token
  force_destroy                   = var.force_destroy
  apex_domain                     = var.apex_domain
  subdomain                       = var.subdomain
  apex_domain_gcp_project         = var.apex_domain_gcp_project
  apex_domain_integration_enabled = var.apex_domain_integration_enabled
}
