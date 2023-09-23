data "google_storage_bucket_object_content" "tekton_pipeline" {
  name   = "pipeline/previous/v${var.tekton_pipeline_version}/release.yaml"
  bucket = "tekton-releases"
}

resource "kubernetes_manifest" "tekton_pipeline" {
  for_each = {
    for manifest in [
      for yamlString in split("---", data.google_storage_bucket_object_content.tekton_pipeline.content)
      : yamldecode(yamlString)
      if strcontains(yamlString, "apiVersion")
    ]
    : join(
      "/",
      [
        lookup(manifest, "apiVersion"),
        lookup(manifest, "kind"),
        lookup(lookup(manifest, "metadata"), "namespace", ""),
        lookup(lookup(manifest, "metadata"), "name"),
      ]
    ) => manifest
  }
  manifest = each.value
}
