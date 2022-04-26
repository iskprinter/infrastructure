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
              value = "http://frontend.iskprinter-pr-$(params.pr-number).svc.cluster.local"
            }
          ]
          command = [
            "node_modules/.bin/cypress"
          ]
          args = [
            "run",
            "--config",
            "videoRecording=false"
          ]
        }
      ]
    }
  })
}
