# EKS on SPOT nodes inside a custom VPC.
# Cost profile: EKS control plane $0.10/h + 2x t3.medium SPOT (~$0.03/h total)
# + 1 NAT gateway (~$0.045/h). ALWAYS `make down-aws` after a session.

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # cost: one NAT, not one per AZ

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    spot = {
      instance_types = ["t3.medium", "t3a.medium"]
      capacity_type  = "SPOT" # ~70% cheaper; fine for a demo fleet
      min_size       = 2
      max_size       = 3
      desired_size   = 2
    }
  }
}
