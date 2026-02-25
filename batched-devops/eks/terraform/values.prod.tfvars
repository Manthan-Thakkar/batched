provision_vpc = false
# If provision_vpc = false then you have to update the values of vpc_id, public_subnet_ids and private_subnet_ids 
provider_region    = "us-east-1"
vpc_id             = "vpc-09ca3b3e0390c01bb"
private_subnet_ids = ["subnet-03493e96000c7447e", "subnet-059f0ca47b537eed2", "subnet-04c458aa2c5177a30"]
# If provision_vpc = true then you have to change the following values as per your needs
vpc_name                 = ""
vpc_cidr                 = ""
vpc_azs                  = ["", "", ""]
vpc_private_subnet_cidrs = ["", "", ""]
vpc_public_subnet_cidrs  = ["", "", ""]
vpc_tags = {
  Terraform   = "true"
  Environment = "prod"
}

#eks cluster values.
eks_cluster_name                             = "batched-eks-prod-cluster"
eks_cluster_version                          = "1.33"
eks_managed_node_group_default_instance_type = ["t3a.medium"]
managed_nodes_min_capacity                   = 1
managed_nodes_max_capacity                   = 10
ebs_disk_size                                = 20
managed_nodes_desired_capacity               = 1
managed_nodes_instance_type_list             = ["t3a.medium"]
managed_nodes_capacity_type                  = "ON_DEMAND"
managed_nodes_tags = {
  Environment = "prod"
  EKSManaged  = "true"
}
ssm_policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
bucket_names   = ["batched-production-logo", "prod-agent-resource-files", "prod-agent-installers-builds", "batched-production-v2.r1", "batched-export-data-prod"]