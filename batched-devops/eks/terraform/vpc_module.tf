module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  count  = var.provision_vpc ? 1 : 0
  name   = var.vpc_name
  cidr   = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnet_cidrs
  public_subnets  = var.vpc_public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = var.vpc_tags
}