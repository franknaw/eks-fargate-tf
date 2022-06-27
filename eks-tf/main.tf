terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.19.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "vpc" {
  filter {
    name = "tag:Name"
    values = [
      "${module.local_resources.vpc_name}-${terraform.workspace}"]
  }
}

data "aws_subnets" "vpc_private_ids" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  tags = {
    Tier = "private"
  }
}

data "aws_subnets" "vpc_public_ids" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  tags = {
    Tier = "public"
  }
}

data "aws_security_group" "eks-alb-sg" {
  tags = {
    Name = "EKS-ALB-SG"
  }
}

module "local_resources" {
  source = "../vars"
}

module "eks_cluster" {
  source              = "./eks/eks_cluster"
  cluster_name        = module.local_resources.eks_cluster_name
  public_subnets      = data.aws_subnets.vpc_public_ids
  private_subnets     = data.aws_subnets.vpc_private_ids
  alb_sg = data.aws_security_group.eks-alb-sg.id
}

module "eks_node_group" {
  source            = "./eks/eks_node_group"
  eks_cluster_name  = module.eks_cluster.cluster_name
  node_group_name   = module.local_resources.node_group_name
  subnet_ids        = data.aws_subnets.vpc_private_ids
  instance_types    = module.local_resources.ng_instance_types
  disk_size         = module.local_resources.disk_size
  desired_nodes     = module.local_resources.desired_nodes
  max_nodes         = module.local_resources.max_nodes
  min_nodes         = module.local_resources.min_nodes
}

module "fargate" {
  source                  = "./eks/fargate"
  eks_cluster_name        = module.eks_cluster.cluster_name
  fargate_profile_name    = module.local_resources.fargate_profile_name
  subnet_ids              = data.aws_subnets.vpc_private_ids
  kubernetes_namespace    = module.local_resources.kubernetes_namespace
}


module "kubernetes" {
  source                = "./kubernetes"
  region                = module.local_resources.region
  vpc_id                = data.aws_vpc.vpc.id
  vpc_cidr              = module.local_resources.vpc_cidr
  eks_cluster_name      = module.eks_cluster.cluster_name
  eks_cluster_endpoint  = module.eks_cluster.endpoint
  eks_oidc_url          = module.eks_cluster.oidc_url
  eks_ca_certificate    = module.eks_cluster.ca_certificate
  namespace             = module.local_resources.kubernetes_namespace
  deployment_name       = module.local_resources.deployment_name
  replicas              = module.local_resources.deployment_replicas
  labels                = module.local_resources.app_labels
  namespace_depends_on  = [ module.fargate.id , module.eks_node_group.id ]
}

