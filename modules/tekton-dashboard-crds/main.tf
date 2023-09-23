data "google_storage_bucket_object_content" "tekton_dashboard" {
  name   = "dashboard/previous/v${var.tekton_dashboard_version}/release.yaml"
  bucket = "tekton-releases"
}

resource "kubernetes_manifest" "tekton_dashboard" {
  for_each = {
    for manifest in [
      for yamlString in split("---", data.google_storage_bucket_object_content.tekton_dashboard.content)
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
