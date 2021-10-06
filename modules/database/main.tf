locals {
  namespace    = "database"
  chart_name   = "neo4j"
  release_name = "neo4j"
}

resource "random_password" "neo4j" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "kubernetes_secret" "neo4j_password" {
  metadata {
    name      = "neo4j-password"
    namespace = local.namespace
  }
  type = "Opaque"
  data = {
    secret = random_password.neo4j.result
  }
}

resource "helm_release" "neo4j" {
  name             = local.release_name
  chart            = "https://github.com/neo4j-contrib/neo4j-helm/releases/download/${var.neo4j_version}/${local.chart_name}-${var.neo4j_version}.tgz"
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

data "kubernetes_persistent_volume_claim" "neo4j" {
  metadata {
    namespace = local.namespace
    name      = "datadir-${local.chart_name}-${local.release_name}-core-0"
  }
}

resource "google_compute_resource_policy" "neo4j_backup_policy" {
  project = var.project
  name    = "neo4j-backup"
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

# This resource has to be created manually
# because there is no way to access the ID
# of the PV that fulfills the PVC.
# Refer to https://github.com/hashicorp/terraform-provider-kubernetes/issues/1232
# for the open feature request.
# resource "google_compute_disk_resource_policy_attachment" "neo4j_backup_policy_attachment" {
#   project = var.project
#   zone    = "${var.region}-a"
#   name    = google_compute_resource_policy.neo4j_backup_policy.name
#   disk    = "pvc-${data.kubernetes_persistent_volume_claim.neo4j.metadata.uid}"
# }
