resource "kubectl_manifest" "acceptance_test_run" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "acceptance-test-run"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "acceptance-test-image"
          description = "The full acceptance test image name and tag"
        },
        {
          name        = "pr-number"
          description = "The application PR number to test"
        }
      ]
      steps = [
        {
          name  = "acceptance-test-run"
          image = "$(params.acceptance-test-image)"
          env = [
            {
              name  = "CYPRESS_BASE_URL"
              value = "frontend.iskprinter-pr-$(params.pr-number).service.cluster.local"
            }
          ]
        }
      ]
      workspaces = [
        {
          mountPath = "/workspace"
          name      = "default"
        }
      ]
    }
  })
}
