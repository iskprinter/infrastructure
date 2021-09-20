resource "google_dns_managed_zone" "apex_domain" {
  project     = var.project
  name        = "iskprinter-com"
  dns_name    = "${var.apex_domain}."
  description = "Managed zone for iskprinter hosts"
}
