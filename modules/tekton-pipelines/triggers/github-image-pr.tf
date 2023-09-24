resource "kubernetes_manifest" "trigger_github_image_pr" {
  manifest = {
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "Trigger"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-image-pr"
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
              name = "eventTypes"
              value = [
                "pull_request"
              ]
            },
            {
              name = "secretRef"
              value = {
                secretName = "github-webhook-secret"
                secretKey  = "secret"
              }
            }
          ]
        },
        {
          name = "only when image PRs are opened"
          ref = {
            kind = "ClusterInterceptor"
            name = "cel"
          }
          params = [
            {
              name  = "filter"
              value = "(requestURL.parseURL().path == \"/github/images\") && (body.action in ['opened', 'synchronize', 'reopened'])"
            }
          ]
        }
      ]
      bindings = [
        {
          kind = "TriggerBinding"
          ref  = "github-pr"
        }
      ]
      template = {
        ref = "github-image-pr"
      }
    }
  }
}
