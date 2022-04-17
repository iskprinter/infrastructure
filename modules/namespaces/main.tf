resource "kubernetes_namespace" "iskprinter" {
  metadata {
    name = "iskprinter"
  }
}
