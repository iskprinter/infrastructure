resource "kubectl_manifest" "task_namespace_create" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "namespace-create"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "namespace"
          description = "The name of the namespace to create"
        }
      ]
      steps = [
        {
          image = "alpine/k8s:${var.alpine_k8s_version}"
          name  = "namespace-create"
          env = [
            {
              name  = "NAMESPACE"
              value = "$(params.namespace)"
            }
          ]
          script = <<-EOF
            #!/bin/bash
            set -euxo pipefail
            if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
              kubectl create namespace "$NAMESPACE"
            fi
            EOF
        }
      ]
    }
  })
}
