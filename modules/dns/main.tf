resource "google_dns_managed_zone" "iskprinter" {
  project     = var.gcp_project
  name        = "iskprinter-com"
  dns_name    = "iskprinter.com."
  description = "Managed zone for iskprinter hosts"
}

resource "google_dns_record_set" "iskprinter_com" {
  project      = var.gcp_project
  managed_zone = google_dns_managed_zone.iskprinter.name
  name         = "iskprinter.com."
  type         = "A"
  rrdatas      = [var.ingress_ip]
  ttl          = 300
}

resource "google_dns_record_set" "wildcard_iskprinter_com" {
  project      = var.gcp_project
  managed_zone = google_dns_managed_zone.iskprinter.name
  name         = "*.iskprinter.com."
  type         = "A"
  rrdatas      = [var.ingress_ip]
  ttl          = 300
}
