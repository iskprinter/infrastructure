resource "kubernetes_manifest" "task_terragrunt_destroy" {
  manifest = {
    apiVersion = "tekton.dev/v1"
    kind       = "Task"
    metadata = {
      name      = "terragrunt-destroy"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "env-name"
          description = "The Terragrunt environment to deploy to"
          type        = "string"
        },
        {
          name        = "pr-number"
          description = "If applicable, the application PR number to deploy"
          default     = "0"
          type        = "string"
        }
      ]
      steps = [
        {
          computeResources = {}
          name             = "terragrunt-destroy"
          image            = "alpine/terragrunt:${var.terraform_version}"
          workingDir       = "$(workspaces.default.path)"
          env = [
            {
              name  = "PR_NUMBER",
              value = "$(params.pr-number)"
            }
          ]
          script = <<-EOF
            #!/bin/sh
            set -eux
            terragrunt destroy -auto-approve --terragrunt-non-interactive --terragrunt-working-dir ./config/$(params.env-name)
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
