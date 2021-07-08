provider "google" {
  project = var.gcp_project
  version = ">= 3.46.0"
}

resource "google_dns_managed_zone" "iskprinter-com" {
  name        = "iskprinter-com"
  dns_name    = "iskprinter.com."
  description = "Managed zone for iskprinter hosts"
}

// Begin Official Jenkins-X content

module "jx" {
  source                          = "github.com/jenkins-x/terraform-google-jx?ref=v1.10.0"
  gcp_project                     = var.gcp_project
  jx2                             = false
  gsm                             = var.gsm
  cluster_name                    = var.cluster_name
  cluster_location                = var.cluster_location
  resource_labels                 = var.resource_labels
  node_machine_type               = var.node_machine_type
  min_node_count                  = var.min_node_count
  max_node_count                  = var.max_node_count
  node_disk_size                  = var.node_disk_size
  node_disk_type                  = var.node_disk_type
  tls_email                       = var.tls_email
  lets_encrypt_production         = var.lets_encrypt_production
  jx_git_url                      = var.jx_git_url
  jx_bot_username                 = var.jx_bot_username
  jx_bot_token                    = var.jx_bot_token
  force_destroy                   = var.force_destroy
  apex_domain                     = var.apex_domain
  subdomain                       = var.subdomain
  apex_domain_gcp_project         = var.apex_domain_gcp_project
  apex_domain_integration_enabled = var.apex_domain_integration_enabled
}

// End Official Jenkins-X content

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "iskprinter"
}

data "kubernetes_service" "nginx_controller" {
  provider = "kubernetes"
  metadata {
    namespace = "nginx"
    name      = "ingress-nginx-controller"
  }
}

resource "google_dns_record_set" "iskprinter-com" {
  managed_zone = google_dns_managed_zone.iskprinter-com.name
  name         = "iskprinter.com."
  type         = "A"
  rrdatas      = [data.kubernetes_service.nginx_controller.load_balancer_ingress.0.ip]
}

// This should be automatically created by the Jenkins module, but it wasn't, in my case.
resource "google_dns_managed_zone" "jenkins-x-iskprinter-com-sub" {
  name        = "jenkins-x-iskprinter-com-sub"
  dns_name    = "jenkins-x.iskprinter.com."
  description = "JX DNS subdomain zone managed by terraform"
}

// This should be automatically created by the Jenkins module, but it wasn't, in my case.
resource "google_dns_record_set" "jenkins-x-iskprinter-com-sub" {
  managed_zone = google_dns_managed_zone.jenkins-x-iskprinter-com-sub.name
  name         = "jenkins-x.iskprinter.com."
  type         = "A"
  rrdatas      = [data.kubernetes_service.nginx_controller.load_balancer_ingress.0.ip]
}
