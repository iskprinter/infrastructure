variable "apex_domain" {
  description = "The apex / parent domain to be allocated to the cluster"
  type        = string
}

variable "gcp_project" {
  description = "The name of the GCP project to use"
  type        = string
}
