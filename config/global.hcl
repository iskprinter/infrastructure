terraform {
  #extra_arguments "init_args" {
  #  commands = [
  #    "init"
  #  ]
  #  arguments = [
  #    "-lockfile=readonly",
  #  ]
  #}
}

locals {
  cert_manager_version                         = "1.6.1"
  cert_manager_kubernetes_namespace            = "cert-manager"
  cert_manager_kubernetes_service_account_name = "cert-manager"
  external_secrets_version                     = "0.5.1"
}
