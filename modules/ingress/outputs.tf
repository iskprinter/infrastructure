output "ip" {
  value = kubernetes_service.nginx.load_balancer_ip
}
