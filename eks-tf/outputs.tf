output "alb_url" {
    value = module.kubernetes.load_balancer_hostname
}

output "terraform_workspace" {
    value = terraform.workspace
}