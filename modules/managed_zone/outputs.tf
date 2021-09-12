output "apex_domain" {
  description = "The apex / parent domain to be allocated to the cluster"
  value       = trimsuffix(google_dns_managed_zone.apex_domain.dns_name, ".")
}
