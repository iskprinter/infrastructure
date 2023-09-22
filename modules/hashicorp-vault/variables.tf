variable "hashicorp_vault_version" {
  type = string
}

variable "gcp_configuration" {
  default = null
  type    = object({
    project = string
    region  = string
  })
}
