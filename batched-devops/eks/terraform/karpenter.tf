data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.24.1"

  cluster_name                  = module.eks.cluster_name
  create_access_entry           = false
  enable_v1_permissions         = true
  irsa_oidc_provider_arn        = module.eks.oidc_provider_arn
  iam_role_use_name_prefix      = false
  iam_role_name                 = "KarpenterControllerRole-${module.eks.cluster_name}"
  enable_irsa                   = true
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "KarpenterNodeRole-${module.eks.cluster_name}"


  node_iam_role_additional_policies = {
    additional2 = var.ssm_policy_arn
    additional3 = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    additional4 = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
    additional5 = aws_iam_policy.s3_access_policy.arn
    additional6 = aws_iam_policy.eventbridge_access_policy.arn
  }
  tags = {
    Environment = "karpenter"
  }
}

resource "helm_release" "karpenter" {
  create_namespace    = true
  namespace           = "karpenter"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.8"
  wait                = false

  values = [
    <<-EOT
    controller:
      resources:
        requests:
          cpu: 500m
          memory: 700Mi
        limits:
          cpu: 500m
          memory: 700Mi
    serviceAccount:
      name: ${module.karpenter.service_account}
      annotations: 
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    nodeSelector:
      kubernetes.io/os: linux
      EKSManaged: 'true'
    featureGates:
      SpotToSpotConsolidation: true
    EOT
  ]
  lifecycle {
    ignore_changes = [ repository_username, repository_password ]
  }
}
