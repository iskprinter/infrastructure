resource "kubectl_manifest" "task_namespace_delete" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "namespace-delete"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "namespace"
          description = "The name of the namespace to delete"
        }
      ]
      steps = [
        {
          image = "alpine/k8s:${var.alpine_k8s_version}"
          name  = "namespace-delete"
          env = [
            {
              name  = "NAMESPACE"
              value = "$(params.namespace)"
            }
          ]
          script = <<-EOF
            #!/bin/bash
            set -euxo pipefail
            if kubectl get namespace "$NAMESPACE" &>/dev/null; then
              kubectl delete namespace "$NAMESPACE"
            fi
            EOF
        }
      ]
    }
  })
}
