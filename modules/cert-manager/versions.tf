terraform {
  required_version = ">= 1.0.0, < 2.0.0"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.0.0, < 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0, < 3.0.0"
    }
  }
}
