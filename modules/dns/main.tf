resource "google_dns_managed_zone" "iskprinter" {
  project     = var.project
  name        = "iskprinter-com"
  dns_name    = "iskprinter.com."
  description = "Managed zone for iskprinter hosts"
}

resource "google_dns_record_set" "iskprinter" {
  project      = var.project
  managed_zone = google_dns_managed_zone.iskprinter.name
  name         = "iskprinter.com."
  type         = "A"
  rrdatas      = [var.ingress_ip]
  ttl          = 300
}
