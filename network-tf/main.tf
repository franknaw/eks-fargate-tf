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

module "local_resources" {
  source = "../vars"
}

//output "vars" {
//  value = [for s in module.local_resources : s]
//}

module "network" {
  source              = "./network"
  vpc_name            = module.local_resources.vpc_name
  vpc_cidr            = module.local_resources.vpc_cidr
  eks_cluster_name    = module.local_resources.eks_cluster_name
  cidr_block_igw      = module.local_resources.cidr_block_igw
}

