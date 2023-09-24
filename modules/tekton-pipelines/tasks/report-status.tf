resource "kubernetes_manifest" "task_report_status" {
  manifest = {
    apiVersion = "tekton.dev/v1"
    kind       = "Task"
    metadata = {
      name      = "report-status"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          name        = "github-status-url"
          description = "The GitHub status URL"
          type        = "string"
        },
        {
          name        = "github-token"
          description = "The GitHub personal access token of the CICD bot"
          type        = "string"
        },
        {
          name        = "github-username"
          description = "The GitHub username of the CICD bot"
          type        = "string"
        },
        {
          name        = "tekton-pipeline-status"
          description = "The Tekton pipeline status"
          type        = "string"
        }
      ]
      steps = [
        {
          computeResources = {}
          image = "alpine:3.14"
          name  = "report-status"
          env = [
            {
              name  = "GITHUB_STATUS_URL"
              value = "$(params.github-status-url)"
            },
            {
              name  = "GITHUB_TOKEN"
              value = "$(params.github-token)"
            },
            {
              name  = "GITHUB_USERNAME"
              value = "$(params.github-username)"
            },
            {
              name  = "TEKTON_PIPELINE_STATUS"
              value = "$(params.tekton-pipeline-status)"
            }
          ]
          command = ["/bin/sh"]
          args = [
            "-c",
            file("${path.module}/report-status.sh")
          ]
        }
      ]
    }
  }
}
