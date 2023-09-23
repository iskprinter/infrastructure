resource "kubectl_manifest" "task_terragrunt_plan" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "terragrunt-plan"
      namespace = "tekton-pipelines"
    }
    spec = {
      steps = [
        {
          name       = "terragrunt-plan"
          image      = "alpine/terragrunt:${var.terraform_version}"
          workingDir = "$(workspaces.default.path)"
          script     = <<-EOF
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
  })
}
