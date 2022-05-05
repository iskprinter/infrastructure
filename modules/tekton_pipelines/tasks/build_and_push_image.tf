resource "kubectl_manifest" "task_build_and_push_image" {
  yaml_body = yamlencode({
    apiVersion = "tekton.dev/v1beta1"
    kind       = "Task"
    metadata = {
      name      = "build-and-push-image"
      namespace = "tekton-pipelines"
    }
    spec = {
      params = [
        {
          description = "The name of the image to build"
          name        = "image-name"
        },
        {
          description = "The tag of the image to build"
          name        = "image-tag"
        }
      ]
      steps = [
        {
          name = "build-and-push-image"
          env = [
            {
              name  = "IMAGE_NAME"
              value = "$(params.image-name)"
            },
            {
              name  = "IMAGE_TAG"
              value = "$(params.image-tag)"
            }
          ]
          image      = "gcr.io/kaniko-project/executor:v${var.kaniko_version}"
          workingDir = "$(workspaces.default.path)"
          args = [
            "--destination=${var.region}-docker.pkg.dev/${var.project}/iskprinter/$(IMAGE_NAME):$(IMAGE_TAG)",
            "--cache=true"
          ]
          resources = {
            limits = {  
              memory = "3Gi"
            }
          }
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
