variable "hashicorp_vault_version" {
  type = string
}

variable "gcp_project" {
  type    = object({
    name    = string
    region  = string
  })
}
