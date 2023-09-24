resource "kubernetes_manifest" "trigger_binding_github_push" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerBinding"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-push"
    }
    spec = {
      params = [
        {
          name  = "repo-name"
          value = "$(body.repository.name)"
        },
        {
          name  = "repo-url"
          value = "$(body.repository.ssh_url)"
        },
        {
          name  = "revision"
          value = "$(body.head_commit.id)"
        }
      ]
    }
  }
}
