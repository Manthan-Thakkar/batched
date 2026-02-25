variable "provision_vpc" {
  type        = bool
  description = "toggle for creating vpc"
}
variable "vpc_name" {
  description = "Name of vpc"
  default     = "dev-vpc"
}

variable "vpc_cidr" {
  description = "vpc cidr address"
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "vpc availablity zone"
  default     = [""]
}

variable "vpc_private_subnet_cidrs" {
  description = "private subnet cidr addresses"
  default     = [""]
}

variable "vpc_public_subnet_cidrs" {
  description = "public subnet cidr addresses"
  default     = [""]
}

variable "vpc_tags" {
  description = "tags to add in vpc resources"
  default     = {}
}

variable "private_subnet_ids" {
  description = "private subnet ids"
  default     = ["subnet-randomstring", "subnet-randomstring", "subnet-randomstring"]
}
# variable "public_subnet_ids" {
#   description = "public subnet ids"
#   default = [ "subnet-randomstring","subnet-randomstring","subnet-randomstring" ]
# }
variable "vpc_id" {
  description = "vpc id"
  default     = "vpc-randomstring"
}
variable "eks_cluster_name" {
  description = "eks cluster name"
}

variable "eks_cluster_version" {
  description = "eks cluster version"

}

variable "eks_managed_node_group_default_instance_type" {
  description = "eks managed node group default instance type"
}

variable "managed_nodes_min_capacity" {
  description = "managed nodes minimum capacity"
}

variable "managed_nodes_max_capacity" {
  description = "managed nodes maximum capacity"
}

variable "managed_nodes_desired_capacity" {
  description = "managed nodes desired capacity"
}

variable "managed_nodes_instance_type_list" {
  description = "managed nodes instance type list"
}

variable "managed_nodes_capacity_type" {
  description = "managed nodes capacity types"
}

variable "managed_nodes_tags" {
  description = "managed nodes tags"
}
variable "ssm_policy_arn" {
  description = "AWS managed ssm policy arn"
}
variable "provider_region" {
  description = "Region of Provider"
}
variable "ebs_disk_size" {

}
variable "bucket_names" {

}