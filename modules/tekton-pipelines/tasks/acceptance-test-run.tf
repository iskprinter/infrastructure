resource "kubernetes_manifest" "acceptance_test_run" {
  manifest = {
    apiVersion = "tekton.dev/v1"
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
          type        = "string"
        },
        {
          name        = "pr-number"
          description = "The application PR number to test"
          type        = "string"
        }
      ]
      steps = [
        {
          computeResources = {}
          name             = "acceptance-test-run"
          image            = "$(params.acceptance-test-image)"
          env = [
            {
              name  = "CYPRESS_BASE_URL"
              value = "http://frontend.iskprinter-pr-$(params.pr-number).svc.cluster.local"
            }
          ]
        }
      ]
    }
  }
}
