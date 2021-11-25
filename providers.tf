provider "google-beta" {}

provider "helm" {
  kubernetes {
    host                   = "https://${module.cluster.cluster_endpoint}"
    client_certificate     = module.cluster.cluster_client_certificate
    client_key             = module.cluster.cluster_client_key
    cluster_ca_certificate = module.cluster.cluster_ca_certificate
  }
  experiments {
    manifest = true
  }
}

provider "kubectl" {
  host                   = "https://${module.cluster.cluster_endpoint}"
  client_certificate     = module.cluster.cluster_client_certificate
  client_key             = module.cluster.cluster_client_key
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
  load_config_file       = false
}

provider "kubernetes" {
  host                   = "https://${module.cluster.cluster_endpoint}"
  client_certificate     = module.cluster.cluster_client_certificate
  client_key             = module.cluster.cluster_client_key
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
  experiments {
    manifest_resource = true
  }
}
