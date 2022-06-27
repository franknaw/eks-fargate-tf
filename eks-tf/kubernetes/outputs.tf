output "load_balancer_hostname" {
  value = kubernetes_ingress.range-ingress.status.0.load_balancer.0.ingress.0.hostname
}