provision_vpc = false
# If provision_vpc = false then you have to update the values of vpc_id, public_subnet_ids and private_subnet_ids 
provider_region    = "us-east-2"
vpc_id             = "vpc-0cd31d7b87027c997"
private_subnet_ids = ["subnet-041a9a869fb270cdb", "subnet-042035f956684fe44", "subnet-0c395635721196993"]
# If provision_vpc = true then you have to change the following values as per your needs
vpc_name                 = ""
vpc_cidr                 = ""
vpc_azs                  = ["", "", ""]
vpc_private_subnet_cidrs = ["", "", ""]
vpc_public_subnet_cidrs  = ["", "", ""]
vpc_tags = {
  Terraform   = "true"
  Environment = "dev"
}

#eks cluster values.
eks_cluster_name                             = "batched-eks-dev-cluster"
eks_cluster_version                          = "1.33"
eks_managed_node_group_default_instance_type = ["t3a.medium"]
managed_nodes_min_capacity                   = 1
managed_nodes_max_capacity                   = 10
ebs_disk_size                                = 20
managed_nodes_desired_capacity               = 1
managed_nodes_instance_type_list             = ["t3a.medium"]
managed_nodes_capacity_type                  = "ON_DEMAND"
managed_nodes_tags = {
  Environment = "dev"
  EKSManaged  = "true"
}
ssm_policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
bucket_names   = ["batched-logos", "agent-resource-files", "agent-installers-builds", "batched-development-v2.r1", "batched-export-data-dev"]