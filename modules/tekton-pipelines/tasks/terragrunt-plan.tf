resource "kubernetes_manifest" "task_terragrunt_plan" {
  manifest = {
    apiVersion = "tekton.dev/v1"
    kind       = "Task"
    metadata = {
      name      = "terragrunt-plan"
      namespace = "tekton-pipelines"
    }
    spec = {
      steps = [
        {
          computeResources = {}
          name             = "terragrunt-plan"
          image            = "alpine/terragrunt:${var.terraform_version}"
          workingDir       = "$(workspaces.default.path)"
          script           = <<-EOF
            #!/bin/sh
            set -eux
            terragrunt plan --terragrunt-working-dir ./config/prod
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
