module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access = false
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs-csi-driver-role.arn
    }
    amazon-cloudwatch-observability = {
      addon_version = "v4.10.0-eksbuild.1"
      most_recent = false
    }
    aws-secrets-store-csi-driver-provider = {
      most_recent = true

      # Pass Helm-style values as JSON (EKS add-on configValues)
      configuration_values = jsonencode({
        # Some add-on versions expect these under this key (subchart)
        "secrets-store-csi-driver" = {
          enableSecretRotation  = true
          rotationPollInterval  = "60s"
          syncSecret = {
            enabled = true
          }
        }

        # If your add-on schema expects top-level keys instead,
        # remove the "secrets-store-csi-driver" wrapper and use:
        # enableSecretRotation = true
        # rotationPollInterval = "2m"
        # syncSecret = { enabled = true }
    })
    }
  }

  vpc_id                   = var.provision_vpc ? module.vpc[0].vpc_id : var.vpc_id
  subnet_ids               = var.provision_vpc ? module.vpc[0].private_subnets : var.private_subnet_ids
  control_plane_subnet_ids = var.provision_vpc ? module.vpc[0].private_subnets : var.private_subnet_ids

  cluster_security_group_additional_rules = {
    ingress_port_tcp = {
      description = "Access To VPN"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["10.10.0.0/16"]
    }
    ingress_port_vpc = {
      description = "Access To VPC"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [data.aws_vpc.eks_vpc.cidr_block]
    }
  }
  eks_managed_node_group_defaults = {
    instance_types = var.eks_managed_node_group_default_instance_type
    iam_role_additional_policies = {
      additional1 = aws_iam_policy.cluster-autoscaler-additional.arn,
      additional2 = var.ssm_policy_arn
      additional3 = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      additional4 = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
      additional5 = aws_iam_policy.s3_access_policy.arn
      additional6 = aws_iam_policy.eventbridge_access_policy.arn
    }
  }
  eks_managed_node_groups = {
    eks-dev-instance = {
      use_custom_launch_template = false
      ami_type                   = "BOTTLEROCKET_x86_64"
      platform                   = "bottlerocket"
      min_size                   = var.managed_nodes_min_capacity
      max_size                   = var.managed_nodes_max_capacity
      desired_size               = var.managed_nodes_desired_capacity
      disk_size                  = var.ebs_disk_size
      instance_types             = var.managed_nodes_instance_type_list
      capacity_type              = var.managed_nodes_capacity_type
      ebs_optimized              = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.ebs_disk_size
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            delete_on_termination = true
          }
        }
      }
      labels = var.managed_nodes_tags
      tags = {
        ExtraTag = "EKS managed node group",
      }
    }
  }
}