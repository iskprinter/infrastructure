# For some reason, this is not working right now.
# I created a question on the helm provider gitub repo:
# https://github.com/hashicorp/terraform-provider-helm/issues/783
# As a workaround, I deployed it manually, with:
# helm install -n ingress nginx-ingress nginx-stable/nginx-ingress --set controller.replicaCount=2

provider "helm" {
  kubernetes {
    # host                   = "https://${var.cluster_endpoint}"
    config_path            = "~/.kube/config"
    # client_certificate     = var.cluster_client_certificate
    # client_key             = var.cluster_client_key
    # cluster_ca_certificate = var.cluster_ca_certificate
  }
}

resource "random_password" "neo4j_password" {
  length = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "helm_release" "neo4j" {
  name             = "neo4j"
  chart            = "https://github.com/neo4j-contrib/neo4j-helm/releases/download/${var.neo4j_version}/neo4j-${var.neo4j_version}.tgz"
  version          = var.neo4j_version
  namespace        = "database"
  create_namespace = true
  set {
    name  = "acceptLicenseAgreement"
    value = "yes"
  }
  set {
    name  = "core.persistentVolume.size"
    value = var.neo4j_persistent_volume_size
  }
  set {
    name  = "imageTag"
    value = "${var.neo4j_version}-community"
  }
  set_sensitive {
    name  = "neo4jPassword"
    value = random_password.neo4j_password.result
  }
  set {
    name  = "readReplica.persistentVolume.size"
    value = var.neo4j_persistent_volume_size
  }
}
