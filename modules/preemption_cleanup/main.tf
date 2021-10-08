resource "kubernetes_namespace" "preemption_cleanup" {
  metadata {
    name = "preemption-cleanup"
  }
}

resource "kubernetes_service_account" "preemption_cleanup" {
  metadata {
    namespace = "preemption-cleanup"
    name      = "preemption-cleanup"
  }
}

resource "kubernetes_cluster_role" "preemption_cleanup_cluster_role" {
  metadata {
    name = "preemption-cleanup"
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "delete", "deletecollection"]
  }
}

resource "kubernetes_cluster_role_binding" "preemption_cleanup_cluster_role_binding" {
  metadata {
    name = "preemption-cleanup"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "preemption-cleanup"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "preemption-cleanup"
    namespace = "preemption-cleanup"
  }
}

resource "kubernetes_cron_job" "preemption_cleanup" {
  metadata {
    namespace = "preemption-cleanup"
    name      = "preemption-cleanup"
  }
  spec {
    concurrency_policy = "Replace"
    schedule           = "*/5 * * * *"
    job_template {
      metadata {
        name = "preemption-cleanup"
      }
      spec {
        template {
          metadata {
            name = "preemption-cleanup"
          }
          spec {
            service_account_name = "preemption-cleanup"
            container {
              name    = "preemption-cleanup"
              image   = "alpine/k8s:${var.alpine_k8s_version}"
              command = ["/bin/bash"]
              args = [
                "-c",
                file("${path.module}/cleanup.sh")
              ]
            }
          }
        }
      }
    }
  }
}
