resource "kubectl_manifest" "acceptance_test_get_image" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
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
        }
      ]
      steps = [
        {
          name       = "acceptance-test-get-image"
          image      = "alpine"
          workingDir = "$(workspaces.default.path)"
          script     = <<-EOF
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
  })
}
