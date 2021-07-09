resource "google_dns_managed_zone" "apex_domain" {
  name        = "iskprinter-com"
  dns_name    = "${var.apex_domain}."
  description = "Managed zone for iskprinter hosts"
}
