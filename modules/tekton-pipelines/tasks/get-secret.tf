resource "kubernetes_manifest" "task_get_secret" {
  manifest = {
    apiVersion = "tekton.dev/v1"
    kind       = "Task"
    metadata = {
      name      = "get-secret"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "secret-key"
          description = "The key of the secret to fetch"
          type        = "string"
        },
        {
          name        = "secret-name"
          description = "The name of the secret to fetch"
          type        = "string"
        },
        {
          name        = "secret-namespace"
          description = "The namespace of the secret to fetch"
          type        = "string"
        }
      ]
      results = [
        {
          name        = "secret-value"
          description = "The value of the secret"
          type        = "string"
        }
      ]
      steps = [
        {
          computeResources = {}
          image            = "alpine/k8s:${var.alpine_k8s_version}"
          name             = "get-secret"
          env = [
            {
              name  = "SECRET_KEY"
              value = "$(params.secret-key)"
            },
            {
              name  = "SECRET_NAME"
              value = "$(params.secret-name)"
            },
            {
              name  = "SECRET_NAMESPACE"
              value = "$(params.secret-namespace)"
            }
          ]
          script = <<-EOF
            #!/bin/bash
            set -euxo pipefail
            set +x
            secret_value=$(
                kubectl get secret "$SECRET_NAME" \
                    -n "$SECRET_NAMESPACE" \
                    -o jsonpath="{.data.$${SECRET_KEY}}" \
                | base64 -d
            )
            echo -n "$secret_value" > $(results.secret-value.path)
            set -x
            EOF
        }
      ]
    }
  }
}
