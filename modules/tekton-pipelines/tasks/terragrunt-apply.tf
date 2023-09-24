resource "kubernetes_manifest" "task_terragrunt_apply" {
  manifest = {
    apiVersion = "tekton.dev/v1"
    kind       = "Task"
    metadata = {
      name      = "terragrunt-apply"
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
          name             = "terragrunt-apply"
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
            if ! terragrunt apply -auto-approve -backup=./backup.tfstate --terragrunt-non-interactive --terragrunt-working-dir ./config/$(params.env-name); then
              echo 'Reverting to prior state' >2
              terragrunt apply -auto-approve -state=./backup.tfstate --terragrunt-non-interactive --terragrunt-working-dir ./config/$(params.env-name)
              exit 1
            fi
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
