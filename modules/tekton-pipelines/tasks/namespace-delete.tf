resource "kubernetes_manifest" "task_namespace_delete" {
  manifest = {
    apiVersion = "tekton.dev/v1"
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
          type        = "string"
        }
      ]
      steps = [
        {
          computeResources = {}
          image            = "alpine/k8s:${var.alpine_k8s_version}"
          name             = "namespace-delete"
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
  }
}
