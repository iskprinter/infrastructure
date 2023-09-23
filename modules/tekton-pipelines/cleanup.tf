# # Cleanup (tekton does not clean up task pods or workspace PVCs)

# resource "kubernetes_service_account" "tekton_cleanup" {
#   metadata {
#     namespace = "tekton-pipelines"
#     name      = "tekton-cleanup"
#   }
# }

# resource "kubernetes_role" "tekton_cleanup_role" {
#   metadata {
#     namespace = "tekton-pipelines"
#     name      = "tekton-cleanup"
#   }
#   rule {
#     api_groups = ["tekton.dev"]
#     resources  = ["pipelineruns"]
#     verbs      = ["list"]
#   }
#   rule {
#     api_groups = [""]
#     resources  = ["pods", "persistentvolumeclaims"]
#     verbs      = ["get", "list", "delete", "deletecollection"]
#   }
# }

# resource "kubernetes_role_binding" "tekton_cleanup_role_binding" {
#   metadata {
#     name      = "tekton-cleanup"
#     namespace = "tekton-pipelines"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "Role"
#     name      = "tekton-cleanup"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = "tekton-cleanup"
#     namespace = "tekton-pipelines"
#   }
# }

# resource "kubernetes_cron_job" "tekton_cleanup" {
#   metadata {
#     namespace = "tekton-pipelines"
#     name      = "tekton-cleanup"
#   }
#   spec {
#     concurrency_policy = "Replace"
#     schedule           = "*/5 * * * *"
#     job_template {
#       metadata {
#         name = "tekton-cleanup"
#       }
#       spec {
#         template {
#           metadata {
#             name = "tekton-cleanup"
#           }
#           spec {
#             service_account_name = "tekton-cleanup"
#             container {
#               name    = "tekton-cleanup"
#               image   = "alpine/k8s:${var.alpine_k8s_version}"
#               command = ["/bin/bash"]
#               args = [
#                 "-c",
#                 file("${path.module}/cleanup.sh")
#               ]
#             }
#           }
#         }
#       }
#     }
#   }
# }
