locals {
  namespace          = "database"
  neo4j_chart_name   = "neo4j"
  neo4j_release_name = "neo4j"
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

resource "random_password" "mongodb" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "helm_release" "mongodb_operator" {
  name             = "mongodb"
  chart            = "${path.module}/mongodb"
  namespace        = local.namespace
  create_namespace = true
  recreate_pods    = true
  set_sensitive {
    name  = "password"
    value = random_password.mongodb.result
  }
}

resource "kubectl_manifest" "mongodb" {
  depends_on = [
    helm_release.mongodb_operator
  ]
  yaml_body = <<-YAML
    apiVersion: mongodbcommunity.mongodb.com/v1
    kind: MongoDBCommunity
    metadata:
      namespace: ${local.namespace}
      name: mongodb
    spec:
      members: 3
      type: ReplicaSet
      version: "4.2.6"
      security:
        authentication:
          modes: ["SCRAM"]
      users:
        - name: admin
          db: admin
          passwordSecretRef: # a reference to the secret that will be used to generate the user's password
            name: admin-password
          roles:
            - name: clusterAdmin
              db: admin
            - name: userAdminAnyDatabase
              db: admin
          scramCredentialsSecretName: my-scram
      additionalMongodConfig:
        storage.wiredTiger.engineConfig.journalCompressor: zlib
      statefulSet:
        spec:
          template:
            spec:
              containers:
                - name: "mongodb-agent"
                  resources:
                    requests:
                      memory: 400M
                    limits:
                      memory: 500M
                - name: "mongod"
                  resources:
                    requests:
                      memory: 400M
                    limits:
                      memory: 500M  
  YAML
}

resource "kubernetes_secret" "mongodb_password" {
  # the user credentials will be generated from this secret
  # once the credentials are generated, this secret is no longer required
  metadata {
    name = "admin-password"
  }
  type = "Opaque"
  binary_data = {
    password = base64encode(random_password.mongodb.result)
  }
}

# Backups

resource "google_compute_resource_policy" "backup_policy" {
  project = var.project
  name    = "backup"
  region  = var.region
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "12:00" # UTC
      }
    }
    retention_policy {
      max_retention_days    = 30
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

data "kubernetes_persistent_volume_claim" "neo4j" {
  metadata {
    namespace = local.namespace
    name      = "datadir-${local.neo4j_chart_name}-${local.neo4j_release_name}-core-0"
  }
}

# This resource has to be created manually
# because there is no way to access the ID
# of the PV that fulfills the PVC.
# Refer to https://github.com/hashicorp/terraform-provider-kubernetes/issues/1232
# for the open feature request.
# resource "google_compute_disk_resource_policy_attachment" "neo4j_backup_policy_attachment" {
#   project = var.project
#   zone    = "${var.region}-a"
#   name    = google_compute_resource_policy.backup_policy.name
#   disk    = "pvc-${data.kubernetes_persistent_volume_claim.neo4j.metadata.uid}"
# }

data "kubernetes_persistent_volume_claim" "mongodb" {
  metadata {
    namespace = local.namespace
    name      = "datadir-${local.neo4j_chart_name}-${local.neo4j_release_name}-core-0"
  }
}

# This resource has to be created manually
# because there is no way to access the ID
# of the PV that fulfills the PVC.
# Refer to https://github.com/hashicorp/terraform-provider-kubernetes/issues/1232
# for the open feature request.
# resource "google_compute_disk_resource_policy_attachment" "mongodb_backup_policy_attachment" {
#   project = var.project
#   zone    = "${var.region}-a"
#   name    = google_compute_resource_policy.backup_policy.name
#   disk    = "pvc-${data.kubernetes_persistent_volume_claim.mongodb.metadata.uid}"
# }
