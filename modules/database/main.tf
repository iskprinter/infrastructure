locals {
  mongodb_connection_secret_key_url = "url"
  mongodb_connection_secret_name    = "mongodb-connection"
  mongodb_resource_name             = "mongodb"
  mongodb_user_admin_username       = "admin"
  mongodb_user_api_username         = "api"
  namespace                         = "database"
  neo4j_chart_name                  = "neo4j"
  neo4j_release_name                = "neo4j"
  release                           = "mongodb"

  mongodb_operator_files = [
    "config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml",
    "config/rbac/role.yaml",
    "config/rbac/role_binding.yaml",
    "config/rbac/service_account.yaml",
    "config/manager/manager.yaml"
  ]
}

# Neo4J

resource "random_password" "neo4j" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "helm_release" "neo4j" {
  name             = local.neo4j_release_name
  chart            = "https://github.com/neo4j-contrib/neo4j-helm/releases/download/${var.neo4j_version}/${local.neo4j_chart_name}-${var.neo4j_version}.tgz"
  version          = var.neo4j_version
  namespace        = local.namespace
  create_namespace = true
  set {
    name  = "acceptLicenseAgreement"
    value = "yes"
  }
  set {
    name  = "core.numberOfServers"
    value = var.neo4j_replicas
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
    value = random_password.neo4j.result
  }
  set {
    name  = "readReplica.persistentVolume.size"
    value = var.neo4j_persistent_volume_size
  }
}

# MongoDB

data "http" "mongodb_community_operator" {
  for_each = toset(local.mongodb_operator_files)
  url      = "https://raw.githubusercontent.com/mongodb/mongodb-kubernetes-operator/v${var.mongodb_operator_version}/${each.value}"
}

data "kubectl_file_documents" "mongodb_community_operator" {
  for_each = data.http.mongodb_community_operator
  content  = each.value.body
}

resource "kubectl_manifest" "mongodb_community_operator" {
  for_each           = merge([for file in data.kubectl_file_documents.mongodb_community_operator : file.manifests]...)
  yaml_body          = each.value
  override_namespace = local.namespace
}

resource "random_password" "mongodb_user_admin_password" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "kubernetes_secret" "mongodb_user_admin_credentials" {
  type = "kubernetes.io/basic-auth"
  metadata {
    namespace = "database"
    name      = "mongodb-user-admin-credentials"
  }
  binary_data = {
    username = base64encode(local.mongodb_user_admin_username)
    password = base64encode(random_password.mongodb_user_admin_password.result)
  }
}

resource "random_password" "mongodb_user_api_password" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "kubernetes_secret" "mongodb_user_api_credentials" {
  type = "kubernetes.io/basic-auth"
  metadata {
    namespace = "database"
    name      = "mongodb-user-api-credentials"
  }
  binary_data = {
    username = base64encode(local.mongodb_user_api_username)
    password = base64encode(random_password.mongodb_user_api_password.result)
  }
}

resource "kubectl_manifest" "mongodb" {
  depends_on = [
    kubectl_manifest.mongodb_community_operator
  ]
  yaml_body = yamlencode({
    apiVersion = "mongodbcommunity.mongodb.com/v1"
    kind       = "MongoDBCommunity"
    metadata = {
      namespace = local.namespace
      name      = local.mongodb_resource_name
    }
    spec = {
      members = var.mongodb_replicas
      type    = "ReplicaSet"
      version = "4.2.6"
      security = {
        authentication = {
          modes = ["SCRAM"]
        }
      }
      users = [
        {
          name = local.mongodb_user_admin_username
          db   = "admin"
          passwordSecretRef = { # a reference to the secret that will be used to generate the user's password
            name = kubernetes_secret.mongodb_user_admin_credentials.metadata[0].name
          }
          roles = [
            {
              name = "clusterAdmin"
              db   = "admin"
            },
            {
              name = "userAdminAnyDatabase"
              db   = "admin"
            }
          ]
          scramCredentialsSecretName = local.mongodb_user_admin_username
        },
        {
          name = local.mongodb_user_api_username
          db   = "admin"
          passwordSecretRef = { # a reference to the secret that will be used to generate the user's password
            name = kubernetes_secret.mongodb_user_api_credentials.metadata[0].name
          }
          roles = [
            {
              name = "readWrite"
              db   = "isk-printer"
            }
          ]
          scramCredentialsSecretName = local.mongodb_user_api_username
        }
      ]
      additionalMongodConfig = {
        "storage.wiredTiger.engineConfig.journalCompressor" = "zlib"
      }
      statefulSet = {
        spec = {
          template = {
            spec = {
              containers = [
                {
                  name = "mongodb-agent"
                  resources = {
                    requests = {
                      memory = "400M"
                    }
                    limits = {
                      memory = "500M"
                    }
                  }
                },
                {
                  name = "mongod"
                  resources = {
                    requests = {
                      memory = "400M"
                    }
                    limits = {
                      memory = "500M"
                    }
                  }
                }
              ]
            }
          }
        }
      }
    }
  })
}

resource "kubernetes_secret" "mongodb_connection" {
  type = "Opaque"
  metadata {
    namespace = "iskprinter"
    name      = local.mongodb_connection_secret_name
  }
  binary_data = {
    (local.mongodb_connection_secret_key_url) = base64encode("mongodb+srv://${urlencode(local.mongodb_user_api_username)}:${urlencode(random_password.mongodb_user_api_password.result)}@${local.release}-svc.${local.namespace}.svc.cluster.local/?ssl=false")
  }
}

# Backups

# The replicas are identical, so we only need to back up one
data "kubernetes_persistent_volume_claim" "neo4j" {
  metadata {
    namespace = local.namespace
    name      = "datadir-${local.neo4j_chart_name}-${local.neo4j_release_name}-core-0"
  }
}

# data "kubernetes_persistent_volume" "neo4j" {
#   metadata {
#     namespace = local.namespace
#     name      = "pvc-${data.kubernetes_persistent_volume_claim.metadata[0].uid}"
#   }
# }

# This resource has to be created manually because there is no data.kubernetes_persistent_volume
# resource in Terraform, which is required to associate the PersistentVolume with the GCP volume.
# Refer to https://github.com/hashicorp/terraform-provider-kubernetes/issues/1232
# for the open feature request.

# resource "google_compute_disk_resource_policy_attachment" "neo4j_backup_policy_attachment" {
#   project = var.project
#   zone    = "${var.region}-a"
#   name    = google_compute_resource_policy.backup_policy.name
#   disk    = "pvc-${data.kubernetes_persistent_volume.neo4j.spec.gcePersistentDisk.pdName}"
# }

# The replicas are identical, so we only need to back up one
data "kubernetes_persistent_volume_claim" "mongodb" {
  count = var.mongodb_replicas
  metadata {
    namespace = local.namespace
    name      = "datadir-${local.neo4j_chart_name}-${local.neo4j_release_name}-core-0"
  }
}

# data "kubernetes_persistent_volume" "mongodb" {
#   metadata {
#     namespace = local.namespace
#     name      = "pvc-${data.kubernetes_persistent_volume_claim.metadata[0].name.uid}"
#   }
# }

# This resource has to be created manually
# because there is no way to access the ID
# of the PV that fulfills the PVC.
# Refer to https://github.com/hashicorp/terraform-provider-kubernetes/issues/1232
# for the open feature request.
# resource "google_compute_disk_resource_policy_attachment" "mongodb_backup_policy_attachment" {

#   project = var.project
#   zone    = "${var.region}-a"
#   name    = google_compute_resource_policy.backup_policy.name
#   disk    = "pvc-${data.kubernetes_persistent_volume.mongodb.spec.gcePersistentDisk.pdName}"
# }
