# Image Registry

resource "google_artifact_registry_repository" "iskprinter" {
  provider      = google-beta
  project       = var.project
  repository_id = "iskprinter"
  location      = var.region
  format        = "DOCKER"
}

# Tekton Pipeline

data "google_storage_bucket_object_content" "tekton_pipeline" {
  name   = "pipeline/previous/v${var.tekton_pipeline_version}/release.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton_pipeline" {
  content = data.google_storage_bucket_object_content.tekton_pipeline.content
}

resource "kubectl_manifest" "tekton_pipeline" {
  count            = length(data.kubectl_file_documents.tekton_pipeline.documents)
  yaml_body        = element(data.kubectl_file_documents.tekton_pipeline.documents, count.index)
  wait_for_rollout = false
}

# Tekton Dashboard

data "google_storage_bucket_object_content" "tekton_dashboard" {
  name   = "dashboard/previous/v${var.tekton_dashboard_version}/tekton-dashboard-release.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton_dashboard" {
  content = data.google_storage_bucket_object_content.tekton_dashboard.content
}

resource "kubectl_manifest" "tekton_dashboard" {
  count            = length(data.kubectl_file_documents.tekton_dashboard.documents)
  yaml_body        = element(data.kubectl_file_documents.tekton_dashboard.documents, count.index)
  wait_for_rollout = false
}

# Tekton Triggers
# Based on https://github.com/sdaschner/tekton-argocd-example/tree/main/pipelinetriggers

data "google_storage_bucket_object_content" "tekton_triggers" {
  name   = "triggers/previous/v${var.tekton_triggers_version}/release.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton_triggers" {
  content = data.google_storage_bucket_object_content.tekton_triggers.content
}

resource "kubectl_manifest" "tekton_triggers" {
  count            = length(data.kubectl_file_documents.tekton_triggers.documents)
  yaml_body        = element(data.kubectl_file_documents.tekton_triggers.documents, count.index)
  wait_for_rollout = false
}

data "google_storage_bucket_object_content" "tekton_triggers_interceptors" {
  name   = "triggers/previous/v${var.tekton_triggers_version}/interceptors.yaml"
  bucket = "tekton-releases"
}

data "kubectl_file_documents" "tekton_triggers_interceptors" {
  content = data.google_storage_bucket_object_content.tekton_triggers_interceptors.content
}

resource "kubectl_manifest" "tekton_triggers_interceptors" {
  count            = length(data.kubectl_file_documents.tekton_triggers_interceptors.documents)
  yaml_body        = element(data.kubectl_file_documents.tekton_triggers_interceptors.documents, count.index)
  wait_for_rollout = false
}

# Service account and credentials

resource "google_service_account" "cicd_bot" {
  project      = var.project
  account_id   = "cicd-bot"
  display_name = "CICD Bot Service Account"
}

resource "kubernetes_secret" "cicd_bot_ssh_key" {
  type = "kubernetes.io/ssh-auth"
  metadata {
    name      = "cicd-bot-ssh-key"
    namespace = "tekton-pipelines"
    annotations = {
      "tekton.dev/git-0" = "github.com"
    }
  }
  binary_data = {
    ssh-privatekey = var.cicd_bot_ssh_private_key_base_64
    known_hosts    = var.github_known_hosts_base_64
  }
}

resource "kubernetes_service_account" "cicd_bot" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "cicd-bot"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.cicd_bot.email
    }
  }
  secret {
    name = kubernetes_secret.cicd_bot_ssh_key.metadata[0].name
  }
}

resource "google_service_account_iam_member" "cicd_bot_iam_workload_identity_user_binding" {
  service_account_id = google_service_account.cicd_bot.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${kubernetes_service_account.cicd_bot.metadata[0].namespace}/${kubernetes_service_account.cicd_bot.metadata[0].name}]"
}

resource "google_project_iam_member" "cicd_bot_storage_object_admin_binding" {
  project = var.project
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.cicd_bot.email}"
}

resource "google_project_iam_member" "cicd_bot_artifact_registry_writer_binding" {
  project = var.project
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cicd_bot.email}"
}

resource "kubernetes_secret" "cicd_bot_personal_access_token" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "cicd-bot-personal-access-token"
  }
  binary_data = {
    username = base64encode(var.cicd_bot_github_username)
    password = var.cicd_bot_personal_access_token_base64
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_role" "cicd_bot" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  metadata {
    namespace = "tekton-pipelines"
    name      = "cicd-bot-role"
  }
  # EventListeners need to be able to fetch all namespaced resources
  rule {
    api_groups = ["triggers.tekton.dev"]
    resources  = ["eventlisteners", "triggerbindings", "triggertemplates", "triggers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    # configmaps is needed for updating logging config
    resources = ["configmaps"]
    verbs     = ["get", "list", "watch"]
  }
  # Permissions to create resources in associated TriggerTemplates
  rule {
    api_groups = ["tekton.dev"]
    resources  = ["pipelineruns", "pipelineresources", "taskruns"]
    verbs      = ["create"]
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["impersonate"]
  }
  rule {
    api_groups     = ["policy"]
    resources      = ["podsecuritypolicies"]
    resource_names = ["tekton-triggers"]
    verbs          = ["use"]
  }
  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = [kubernetes_secret.cicd_bot_personal_access_token.metadata[0].name]
    verbs          = ["get"]
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_role_binding" "cicd_bot" {
  metadata {
    namespace = kubernetes_service_account.cicd_bot.metadata[0].namespace
    name      = "cicd-bot-role-binding"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account.cicd_bot.metadata[0].namespace
    name      = kubernetes_service_account.cicd_bot.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.cicd_bot.metadata[0].name
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_cluster_role" "cicd_bot" {
  metadata {
    name = "cicd-bot-cluster-role"
  }
  rule {
    # EventListeners need to be able to fetch any clustertriggerbindings, and clusterinterceptors
    api_groups = ["triggers.tekton.dev"]
    resources  = ["clustertriggerbindings", "clusterinterceptors"]
    verbs      = ["get", "list", "watch"]
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_cluster_role_binding" "cicd_bot" {
  metadata {
    name = "cicd-bot-cluster-role-binding"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account.cicd_bot.metadata[0].namespace
    name      = kubernetes_service_account.cicd_bot.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cicd_bot.metadata[0].name
  }
}

resource "random_password" "secret_github_webhook" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/secret.yaml
resource "kubernetes_secret" "secret_github_webhook" {
  type = "Opaque"
  metadata {
    name        = "github-webhook"
    namespace   = "tekton-pipelines"
    annotations = {}
    labels      = {}
  }
  binary_data = {
    secretToken = base64encode(random_password.secret_github_webhook.result)
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubectl_manifest" "event_listener_github" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "EventListener"
    metadata = {
      name      = "github"
      namespace = "tekton-pipelines"
      finalizers = [
        "eventlisteners.triggers.tekton.dev",
      ]
    }
    spec = {
      namespaceSelector  = {}
      serviceAccountName = "cicd-bot"
      triggers = [
        {
          triggerRef = "github"
        }
      ]
      resources = {
        kubernetesResource = {
          spec = {
            template = {
              spec = {
                serviceAccountName = "cicd-bot"
                containers = [
                  {
                    name = ""
                    resources = {
                      requests = {
                        memory = "64Mi"
                        # cpu    = "250m"
                      }
                      limits = {
                        memory = "128Mi"
                        # cpu    = "500m"
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }
  })
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubectl_manifest" "trigger_github" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "Trigger"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github"
    }
    spec = {
      interceptors = [
        {
          ref = {
            kind = "ClusterInterceptor"
            name = "github"
          }
          params = [
            {
              name = "secretRef"
              value = {
                secretName = "github-webhook"
                secretKey  = "secretToken"
              }
            },
            {
              name = "eventTypes"
              value = [
                "pull_request"
                # "push",
              ]
            },
          ]
        },
        {
          name = "only when PRs are opened"
          ref = {
            kind = "ClusterInterceptor"
            name = "cel"
          }
          params = [
            {
              name = "filter"
              # value = "body.ref == 'refs/heads/main'"
              value = "body.action in ['opened', 'synchronize', 'reopened']"
            }
          ]
        }
      ]
      bindings = [
        {
          kind = "TriggerBinding"
          ref  = "github"
        }
      ]
      template = {
        ref = "github"
      }
    }
  })
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubectl_manifest" "trigger_binding_github" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerBinding"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github"
    }
    spec = {
      params = [
        {
          name  = "image-name"
          value = "$(body.repository.name)"
        },
        {
          name  = "revision"
          value = "$(body.pull_request.head.sha)"
        },
        {
          name  = "repo-url"
          value = "$(body.repository.ssh_url)"
        },
        {
          name  = "github-status-url"
          value = "$(body.pull_request.statuses_url)"
        }
      ]
    }
  })
}

# Based on the example at https://github.com/tektoncd/triggers/blob/main/docs/triggertemplates.md
resource "kubectl_manifest" "trigger_template_github" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerTemplate"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github"
    }
    spec = {
      params = [
        {
          name = "image-name"
        },
        {
          name = "repo-url"
        },
        {
          name = "revision"
        },
        {
          name = "github-status-url"
        }
      ]
      resourcetemplates = [
        {
          apiVersion = "tekton.dev/v1beta1"
          kind       = "PipelineRun"
          metadata = {
            generateName = "github-pr-"
          }
          spec = {
            serviceAccountName = "cicd-bot"
            pipelineRef = {
              name = "github-pr"
            }
            params = [
              {
                name  = "image-name"
                value = "$(tt.params.image-name)"
              },
              {
                name  = "repo-url"
                value = "$(tt.params.repo-url)"
              },
              {
                name  = "revision"
                value = "$(tt.params.revision)"
              },
              {
                name  = "github-status-url"
                value = "$(tt.params.github-status-url)"
              }
            ]
            workspaces = [
              {
                name = "default"
                volumeClaimTemplate = {
                  spec = {
                    accessModes = [
                      "ReadWriteOnce"
                    ]
                    resources = {
                      requests = {
                        storage = "512Mi"
                      }
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  })
}

# Based on the example at https://tekton.dev/vault/pipelines-v0.26.0/pipelines/#pipelines
resource "kubectl_manifest" "pipeline_github_pr" {
  depends_on = [
    kubectl_manifest.tekton_triggers,
    kubectl_manifest.tekton_triggers_interceptors
  ]
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Pipeline"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-pr"
    }
    spec = {
      params = [
        {
          name        = "image-name"
          type        = "string"
          description = "The name of the repo to build"
        },
        {
          name        = "repo-url"
          type        = "string"
          description = "The URL of the repo to build"
        },
        {
          name        = "revision"
          type        = "string"
          description = "The revision to of the repo to build"
        },
        {
          name        = "github-status-url"
          type        = "string"
          description = "The GitHub status URL"
        }
      ]
      workspaces = [
        {
          name = "default" # Must match the name in the PipelineRun?
        }
      ]
      tasks = [
        {
          name = "report-initial-status"
          params = [
            {
              name  = "github-status-url"
              value = "$(params.github-status-url)"
            },
            {
              name  = "tekton-pipeline-status"
              value = "None"
            }
          ]
          taskRef = {
            name = "report-status"
          }
        },
        {
          name = "github-checkout"
          taskRef = {
            name = "github-checkout"
          }
          workspaces = [
            {
              name      = "default" # Must match what the git-clone task expects.
              workspace = "default" # Must match above
            }
          ]
          params = [
            {
              name  = "repo-url"
              value = "$(params.repo-url)"
            },
            {
              name  = "revision"
              value = "$(params.revision)"
            }
          ]
        },
        {
          runAfter = [
            "github-checkout"
          ]
          name = "construct-build-image"
          params = [
            {
              name  = "build-image-name"
              value = "$(params.image-name)-pipeline"
            },
            {
              name  = "build-image-tag"
              value = "$(params.revision)"
            }
          ]
          workspaces = [
            {
              name      = "default"
              workspace = "default" # Must match above
            }
          ]
          taskRef = {
            name = "construct-build-image"
          }
        },
        {
          runAfter = [
            "construct-build-image"
          ]
          name = "run-build"
          params = [
            {
              name  = "build-image-name"
              value = "$(params.image-name)-pipeline"
            },
            {
              name  = "build-image-tag"
              value = "$(params.revision)"
            }
          ]
          workspaces = [
            {
              name      = "default"
              workspace = "default"
            }
          ]
          taskRef = {
            name = "run-build"
          }
        }
      ]
      finally = [
        {
          name = "report-final-status"
          params = [
            {
              name  = "github-status-url"
              value = "$(params.github-status-url)"
            },
            {
              name  = "tekton-pipeline-status"
              value = "$(tasks.status)"
            }
          ]
          taskRef = {
            name = "report-status"
          }
        }
      ]
    }
  })
}

resource "kubectl_manifest" "task_github_checkout" {
  yaml_body = <<-YAML
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      namespace: tekton-pipelines
      name: github-checkout
    spec:
      params:
      - name: repo-url
        description: Repository URL to clone from.
        type: string
      - name: revision
        description: Revision to checkout. (branch, tag, sha, ref, etc...)
        type: string
      workspaces:
      - name: default
        mountPath: "/workspace"
      steps:
      - name: github-checkout
        image: "alpine/git:v2.32.0"
        workingDir: $(workspaces.default.path)
        env:
        - name: REPO_URL
          value: $(params.repo-url)
        - name: REVISION
          value: $(params.revision)
        script: |
          #!/bin/sh
          set -eux
          git init
          git remote add origin "$${REPO_URL}"
          git fetch origin "$${REVISION}" --depth=1
          git reset --hard FETCH_HEAD
  YAML
}

resource "kubectl_manifest" "task_construct_build_image" {
  yaml_body = <<-EOT
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: construct-build-image
      namespace: tekton-pipelines
    spec:
      params:
      - description: The name of the build image to use
        name: build-image-name
      - description: The tag of the build image to use
        name: build-image-tag
      results:
      - description: The name and tag of the image to run
        name: build-image-name-and-tag
      steps:
      - env:
        - name: IMAGE_NAME
          value: $(params.build-image-name)
        - name: IMAGE_TAG
          value: $(params.build-image-tag)
        image: gcr.io/kaniko-project/executor:v1.3.0
        name: construct-build-image
        workingDir: $(workspaces.default.path)
        args: [
          "--context=./cicd",
          "--destination=${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.iskprinter.name}/$(IMAGE_NAME):$(IMAGE_TAG)"
        ]
      workspaces:
      - mountPath: /workspace
        name: default
  EOT
}

resource "kubectl_manifest" "task_run_build" {
  yaml_body = <<-YAML
    apiVersion: tekton.dev/v1beta1
    kind: Task
    metadata:
      name: run-build
      namespace: tekton-pipelines
    spec:
      params:
      - description: The name of the build image to use
        name: build-image-name
      - description: The tag of the build image to use
        name: build-image-tag
      steps:
      - image: "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.iskprinter.name}/$(params.build-image-name):$(params.build-image-tag)"
        name: run-build
        script: |
          #!/bin/sh
          set -eux
          if ! [ -d ./cicd ] || ! [ -f ./cicd/tekton.sh ]; then
            echo 'Error: unable to find a ./cicd/tekton.sh file to run' >2
            exit 1
          fi
          ./cicd/tekton.sh
        workingDir: $(workspaces.default.path)
      workspaces:
      - mountPath: /workspace
        name: default
  YAML
}

resource "kubectl_manifest" "task_report_status" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "report-status"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          description = "The GitHub status URL"
          name        = "github-status-url"
        },
        {
          description = "The Tekton pipeline status"
          name        = "tekton-pipeline-status"
        }
      ]
      steps = [
        {
          image = "alpine/k8s:${var.alpine_k8s_version}"
          name  = "report-status"
          env = [
            {
              name  = "TEKTON_PIPELINE_STATUS"
              value = "$(params.tekton-pipeline-status)"
            },
            {
              name  = "GITHUB_STATUS_URL"
              value = "$(params.github-status-url)"
            },
            {
              name  = "GITHUB_USERNAME"
              value = var.cicd_bot_github_username
            },
            {
              name  = "GITHUB_TOKEN_SECRET_NAMESPACE"
              value = kubernetes_secret.cicd_bot_personal_access_token.metadata[0].namespace
            },
            {
              name  = "GITHUB_TOKEN_SECRET_NAME"
              value = kubernetes_secret.cicd_bot_personal_access_token.metadata[0].name
            }
          ]
          command = ["/bin/bash"]
          args = [
            "-c",
            file("${path.module}/report_status.sh")
          ]
        }
      ]
    }
  })
}

resource "google_dns_record_set" "triggers_tekon_iskprinter_com" {
  project      = var.project
  managed_zone = var.dns_managed_zone_name
  name         = "triggers.tekton.iskprinter.com."
  type         = "A"
  rrdatas      = [var.ingress_ip]
  ttl          = 300
}

resource "kubernetes_ingress" "tekton_triggers_ingress" {
  metadata {
    name      = "tekton-triggers-ingress"
    namespace = "tekton-pipelines"
    annotations = {
      "kubernetes.io/ingress.class"              = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }
  spec {
    rule {
      host = "triggers.tekton.iskprinter.com"
      http {
        path {
          path = "/"
          backend {
            service_name = "el-github"
            service_port = 8080
          }
        }
      }
    }
    tls {
      hosts = [
        "triggers.tekton.iskprinter.com"
      ]
      secret_name = "tls-triggers-tekton-iskprinter-com"
    }
  }
}

resource "kubectl_manifest" "certificate_triggers_tekton_iskprinter_com" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "certificate-triggers-tekton-iskprinter-com"
      namespace = "tekton-pipelines"
    }
    spec = {
      secretName = "tls-triggers-tekton-iskprinter-com"
      issuerRef = {
        # The issuer created previously
        kind = "ClusterIssuer"
        name = "lets-encrypt-prod"
      }
      dnsNames = [
        "triggers.tekton.iskprinter.com"
      ]
    }
  })
}

# Cleanup (tekton does not clean up task pods or workspace PVCs)

resource "kubernetes_service_account" "tekton_cleanup" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "tekton-cleanup"
  }
}

resource "kubernetes_role" "tekton_cleanup_role" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "tekton-cleanup"
  }
  rule {
    api_groups = ["tekton.dev"]
    resources  = ["pipelineruns"]
    verbs      = ["list"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "persistentvolumeclaims"]
    verbs      = ["get", "list", "delete", "deletecollection"]
  }
}

resource "kubernetes_role_binding" "tekton_cleanup_role_binding" {
  metadata {
    name      = "tekton-cleanup"
    namespace = "tekton-pipelines"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "tekton-cleanup"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "tekton-cleanup"
    namespace = "tekton-pipelines"
  }
}

resource "kubernetes_cron_job" "tekton_cleanup" {
  metadata {
    namespace = "tekton-pipelines"
    name      = "tekton-cleanup"
  }
  spec {
    concurrency_policy = "Replace"
    schedule           = "*/5 * * * *"
    job_template {
      metadata {
        name = "tekton-cleanup"
      }
      spec {
        template {
          metadata {
            name = "tekton-cleanup"
          }
          spec {
            service_account_name = "tekton-cleanup"
            container {
              name    = "tekton-cleanup"
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
