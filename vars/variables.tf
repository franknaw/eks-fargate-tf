terraform {
  experiments = [module_variable_optional_attrs]
}

variable "dev" {
  type = object({
    region               = optional(string)
    vpc_name             = optional(string)
    vpc_cidr             = optional(string)
    alb_sg               = optional(string)
    cidr_block_igw       = optional(string)
    eks_cluster_name     = optional(string)
    node_group_name      = optional(string)
    ng_instance_types    = optional(list(string))
    disk_size            = optional(number)
    desired_nodes        = optional(number)
    max_nodes            = optional(number)
    min_nodes            = optional(number)
    deployment_replicas  = optional(number)
    fargate_profile_name = optional(string)
    kubernetes_namespace = optional(string)
    deployment_name      = optional(string)
    fargate_profile_name = optional(string)
    app_labels           = optional(map(string))
  })

  default = {
    region               = "us-east-1"
    vpc_name             = "eks-range"
    vpc_cidr             = "172.2.0.0/16"
    alb_sg               = ""
    cidr_block_igw       = "0.0.0.0/0"
    eks_cluster_name     = "eks_cluster"
    node_group_name      = "eks_nodegroup"
    ng_instance_types    = ["t2.micro"]
    disk_size            = 10
    desired_nodes        = 2
    max_nodes            = 2
    min_nodes            = 1
    fargate_profile_name = "eks_fargate"
    kubernetes_namespace = "range"
    deployment_name      = "range-api"
    deployment_replicas  = 2
    app_labels = {
      "app"  = "range"
      "tier" = "development"
    }
  }

  description = "Variables"
}
