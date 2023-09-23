variable "cert_manager_operator_version" {
  type = string
}

variable "kubernetes_provider" {
  type = string
}

variable "project" {
  default = "N/A"
  type    = string
}

variable "use_real_lets_encrypt_certs" {
  type = bool
}
