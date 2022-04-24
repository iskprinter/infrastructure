resource "kubectl_manifest" "task_terragrunt_apply" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "terragrunt-apply"
      namespace = "tekton-pipelines"
    }
    spec = {
      steps = [
        {
          name       = "terragrunt-apply"
          image      = "alpine/terragrunt:${var.terraform_version}"
          workingDir = "$(workspaces.default.path)"
          script     = <<-EOF
            #!/bin/sh
            set -eux
            if ! terragrunt apply -auto-approve -backup=./backup.tfstate --terragrunt-non-interactive --terragrunt-working-dir ./config/prod; then
              echo 'Reverting to prior state' >2
              terragrunt apply -auto-approve -state=./backup.tfstate --terragrunt-non-interactive --terragrunt-working-dir ./config/prod
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
  })
}
