resource "kubectl_manifest" "task_github_checkout_commit" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      "namespace" = "tekton-pipelines"
      "name"      = "github-checkout-commit"
    }
    spec = {
      params = [
        {
          name        = "repo-url"
          description = "Repository URL to clone from."
          type        = "string"
        },
        {
          name        = "revision"
          description = "Revision to checkout. (branch, tag, sha, ref, etc...)"
          type        = "string"
        }
      ]
      "workspaces" = [
        {
          name      = "default"
          mountPath = "/workspace"
        }
      ]
      steps = [
        {
          name       = "github-checkout"
          image      = "alpine/git:v2.32.0"
          workingDir = "$(workspaces.default.path)"
          env = [
            {
              name  = "REPO_URL"
              value = "$(params.repo-url)"
            },
            {
              name  = "REVISION"
              value = "$(params.revision)"
            }
          ]
          script = <<-EOF
            #!/bin/sh
            set -eux
            git init
            git remote add origin "$${REPO_URL}"
            git fetch origin "$${REVISION}" --depth=1
            git reset --hard FETCH_HEAD
            EOF
        }
      ]
    }
  })
}
