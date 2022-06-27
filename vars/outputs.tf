output "terraform_workspace" {
  value = terraform.workspace
}

output "region" {
  value = var.dev["region"]
}

output "vpc_name" {
  value = var.dev["vpc_name"]
}

output "vpc_cidr" {
  value = var.dev["vpc_cidr"]
}

output "alb_sg" {
  value = var.dev["alb_sg"]
}

output "cidr_block_igw" {
  value = var.dev["cidr_block_igw"]
}

output "eks_cluster_name" {
  value = var.dev["vpc_name"]
}

output "node_group_name" {
  value = var.dev["node_group_name"]
}

output "ng_instance_types" {
  value = var.dev["ng_instance_types"]
}

output "disk_size" {
  value = var.dev["disk_size"]
}

output "desired_nodes" {
  value = var.dev["desired_nodes"]
}

output "max_nodes" {
  value = var.dev["max_nodes"]
}

output "min_nodes" {
  value = var.dev["min_nodes"]
}

output "fargate_profile_name" {
  value = var.dev["fargate_profile_name"]
}

output "kubernetes_namespace" {
  value = var.dev["kubernetes_namespace"]
}

output "deployment_name" {
  value = var.dev["deployment_name"]
}

output "deployment_replicas" {
  value = var.dev["deployment_replicas"]
}

output "app_labels" {
  value = var.dev["app_labels"]
}
