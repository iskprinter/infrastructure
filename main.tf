terraform {
  backend "gcs" {
    bucket = "iskprinter-terraform-state"
  }
}

module "managed_zone" {
  source      = "./modules/managed_zone/"
  gcp_project = var.gcp_project
  apex_domain = var.apex_domain
}

module "jenkins_x" {
  source                          = "github.com/jenkins-x/terraform-google-jx?ref=v1.10.7"
  gcp_project                     = var.gcp_project
  jx2                             = false
  gsm                             = false
  cluster_name                    = var.cluster_name
  cluster_location                = var.cluster_location
  resource_labels                 = { "provider" : "jx" }
  node_machine_type               = var.node_machine_type
  min_node_count                  = var.min_node_count
  max_node_count                  = var.max_node_count
  node_disk_size                  = var.node_disk_size
  node_disk_type                  = var.node_disk_type
  tls_email                       = var.tls_email
  lets_encrypt_production         = true
  jx_git_url                      = var.jx_git_url
  jx_bot_username                 = var.jx_bot_username
  jx_bot_token                    = var.jx_bot_token
  apex_domain                     = module.managed_zone.apex_domain
  apex_domain_gcp_project         = var.gcp_project
  apex_domain_integration_enabled = true
}
