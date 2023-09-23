# Variables provided by Terragrunt

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "alpine_k8s_version" {
  type = string
}

variable "kaniko_version" {
  type = string
}

variable "terraform_version" {
  type = string
}

# Defaults

variable "cicd_bot_name" {
  type    = string
  default = "cicd-bot"
}
