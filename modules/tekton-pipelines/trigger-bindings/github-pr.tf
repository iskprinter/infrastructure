# Based on the example at https://github.com/tektoncd/triggers/blob/v0.15.2/examples/v1beta1/github/github-eventlistener-interceptor.yaml
resource "kubernetes_manifest" "trigger_binding_github_pr" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "TriggerBinding"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-pr"
    }
    spec = {
      params = [
        {
          name  = "github-status-url"
          value = "$(body.pull_request.statuses_url)"
        },
        {
          name  = "pr-number"
          value = "$(body.number)"
        },
        {
          name  = "repo-name"
          value = "$(body.repository.name)"
        },
        {
          name  = "repo-url"
          value = "$(body.repository.ssh_url)"
        }
      ]
    }
  }
}
