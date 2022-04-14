module "cluster" {
  source             = "./modules/cluster/"
  project            = var.project
  location           = "${var.region}-a"
  min_node_8gb_count = var.min_node_8gb_count
  max_node_8gb_count = var.max_node_8gb_count
}

module "backups" {
  source  = "./modules/backups"
  project = var.project
  region  = var.region
}
