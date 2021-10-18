resource "google_dns_managed_zone" "iskprinter" {
  project     = var.project
  name        = "iskprinter-com"
  dns_name    = "iskprinter.com."
  description = "Managed zone for iskprinter hosts"
}
