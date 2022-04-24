resource "kubectl_manifest" "trigger_github_release_push" {
  yaml_body = yamlencode({
    apiVersion = "triggers.tekton.dev/v1beta1"
    kind       = "Trigger"
    metadata = {
      namespace = "tekton-pipelines"
      name      = "github-release-push"
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
                "push"
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
              value = "(requestURL.parseURL().path == \"/github/releases\") && (body.ref == \"refs/heads/main\")"
            }
          ]
        }
      ]
      bindings = [
        {
          kind = "TriggerBinding"
          ref  = "github-push"
        }
      ]
      template = {
        ref = "github-release-push"
      }
    }
  })
}
