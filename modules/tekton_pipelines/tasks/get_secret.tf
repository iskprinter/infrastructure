resource "kubectl_manifest" "task_get_secret" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
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
        },
        {
          name        = "secret-name"
          description = "The name of the secret to fetch"
        },
        {
          name        = "secret-namespace"
          description = "The namespace of the secret to fetch"
        }
      ]
      results = [
        {
          name        = "secret-value"
          description = "The value of the secret"
        }
      ]
      steps = [
        {
          image = "alpine/k8s:${var.alpine_k8s_version}"
          name  = "get-secret"
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
            secret_value=$(
                kubectl get secret "$SECRET_NAME" \
                    -n "$SECRET_NAMESPACE" \
                    -o jsonpath="{.data.$${SECRET_KEY}}" \
                | base64 -d
            )
            set +x
            echo -n "$secret_value" > $(results.secret-value.path)
            set -x
            EOF
        }
      ]
    }
  })
}
