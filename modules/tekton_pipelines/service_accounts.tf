resource "google_service_account" "cicd_bot" {
  project      = var.project
  account_id   = "cicd-bot"
  display_name = "CICD Bot Service Account"
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
    name = "cicd-bot-ssh-key"
  }
}

resource "google_service_account_iam_member" "cicd_bot_iam_workload_identity_user_member" {
  service_account_id = google_service_account.cicd_bot.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${kubernetes_service_account.cicd_bot.metadata[0].namespace}/${kubernetes_service_account.cicd_bot.metadata[0].name}]"
}

resource "google_project_iam_custom_role" "cicd_bot_role" {
  project = var.project
  role_id = "cicd_bot"
  title   = "CICD Bot"
  permissions = [
    "artifactregistry.repositories.downloadArtifacts",
    "artifactregistry.repositories.uploadArtifacts",
    "compute.instanceGroupManagers.get",
    "container.clusters.get",
    "container.cronJobs.create",
    "container.cronJobs.delete",
    "container.cronJobs.get",
    "container.cronJobs.update",
    "container.customResourceDefinitions.create",
    "container.customResourceDefinitions.delete",
    "container.customResourceDefinitions.get",
    "container.customResourceDefinitions.update",
    "container.deployments.create",
    "container.deployments.delete",
    "container.deployments.get",
    "container.deployments.update",
    "container.ingresses.create",
    "container.ingresses.delete",
    "container.ingresses.get",
    "container.ingresses.update",
    "container.jobs.create",
    "container.jobs.delete",
    "container.jobs.get",
    "container.jobs.update",
    "container.namespaces.get",
    "container.persistentVolumeClaims.create",
    "container.persistentVolumeClaims.delete",
    "container.persistentVolumeClaims.get",
    "container.persistentVolumeClaims.update",
    "container.roleBindings.create",
    "container.roleBindings.delete",
    "container.roleBindings.get",
    "container.roleBindings.update",
    "container.roles.create",
    "container.roles.delete",
    "container.roles.get",
    "container.roles.update",
    "container.secrets.create",
    "container.secrets.delete",
    "container.secrets.get",
    "container.secrets.list",
    "container.secrets.update",
    "container.serviceAccounts.create",
    "container.serviceAccounts.delete",
    "container.serviceAccounts.get",
    "container.serviceAccounts.update",
    "container.services.create",
    "container.services.delete",
    "container.services.get",
    "container.services.update",
    "container.thirdPartyObjects.create",
    "container.thirdPartyObjects.delete",
    "container.thirdPartyObjects.get",
    "container.thirdPartyObjects.update",
    "dns.changes.create",
    "dns.changes.get",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list",
    "dns.resourceRecordSets.update",
    "storage.buckets.get",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
  ]
}

resource "google_project_iam_member" "cicd_bot_role_member" {
  project = var.project
  role    = google_project_iam_custom_role.cicd_bot_role.name
  member  = "serviceAccount:${google_service_account.cicd_bot.email}"
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_role" "tekton_triggers" {
    metadata {
    namespace = "tekton-pipelines"
    name      = "tekton-triggers"
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
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_role_binding" "tekton_triggers" {
  metadata {
    namespace = kubernetes_role.tekton_triggers.metadata[0].namespace
    name      = "tekton-triggers"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account.cicd_bot.metadata[0].namespace
    name      = kubernetes_service_account.cicd_bot.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.tekton_triggers.metadata[0].name
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.1/examples/rbac.yaml
resource "kubernetes_cluster_role" "tekton_triggers" {
  metadata {
    name = "tekton-triggers"
  }
  rule {
    # EventListeners need to be able to fetch any clustertriggerbindings, and clusterinterceptors
    api_groups = ["triggers.tekton.dev"]
    resources  = ["clustertriggerbindings", "clusterinterceptors"]
    verbs      = ["get", "list", "watch"]
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_cluster_role_binding" "tekton_triggers" {
  metadata {
    name = "tekton-triggers"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account.cicd_bot.metadata[0].namespace
    name      = kubernetes_service_account.cicd_bot.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.tekton_triggers.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "cicd_bot" {
  metadata {
    name = "cicd-bot"
  }
  # EventListeners need to be able to fetch all namespaced resources
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get"]
  }
}

# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/rbac.yaml
resource "kubernetes_cluster_role_binding" "cicd_bot" {
  metadata {
    name = "cicd-bot"
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
