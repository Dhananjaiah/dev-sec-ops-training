terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "kafka-platform-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "kafka-platform-terraform-locks"
  }
}

module "networking" {
  source = "../../modules/networking"

  environment          = "prod"
  aws_region           = var.aws_region
  vpc_cidr             = "10.10.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  public_subnet_cidrs  = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
}

module "eks" {
  source = "../../modules/eks"

  environment            = "prod"
  aws_region             = var.aws_region
  cluster_name           = "prod-kafka-cluster"
  cluster_version        = "1.28"
  vpc_id                 = module.networking.vpc_id
  private_subnet_ids     = module.networking.private_subnet_ids
  node_group_min_size    = 3
  node_group_max_size    = 15
  node_group_desired_size = 6
  node_instance_types    = ["m5.2xlarge"]
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}

output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
}
