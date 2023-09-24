resource "kubernetes_manifest" "acceptance_test_get_image" {
  manifest = {
    apiVersion = "tekton.dev/v1"
    kind       = "Task"
    metadata = {
      name      = "acceptance-test-get-image"
      namespace = "tekton-pipelines"
    }
    spec = {
      results = [
        {
          name        = "acceptance-test-image"
          description = "The full acceptance test image name and tag"
          type        = "string"
        }
      ]
      steps = [
        {
          computeResources = {}
          name             = "acceptance-test-get-image"
          image            = "alpine"
          workingDir       = "$(workspaces.default.path)"
          script           = <<-EOF
            #!/bin/sh
            set -eux
            acceptance_test_image=$(sed -n -E 's/^ +acceptance_test_image += "(.*)"$/\1/p' ./config/pr/terragrunt.hcl)
            echo -n "$acceptance_test_image" | tee $(results.acceptance-test-image.path)
            EOF
        }
      ]
      workspaces = [
        {
          mountPath = "/workspace"
          name      = "default"
        }
      ]
    }
  }
}
