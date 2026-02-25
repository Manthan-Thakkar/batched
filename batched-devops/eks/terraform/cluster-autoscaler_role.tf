resource "aws_iam_policy" "cluster-autoscaler-additional" {
  name = "${module.eks.cluster_name}-cluster-autoscaler-node-group-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
data "aws_iam_policy_document" "clusterautoscaler-role-policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["${module.eks.oidc_provider_arn}"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test = "StringEquals"

      values   = ["sts.amazonaws.com"]
      variable = "${module.eks.oidc_provider}:aud"
    }
    condition {
      test = "StringEquals"

      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
      variable = "${module.eks.oidc_provider}:sub"
    }
  }
}

data "aws_iam_policy_document" "cluster_autoscaler_policy" {
  statement {
    sid    = "VisualEditor0"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/${module.eks.cluster_name}"
      values   = ["owned"]
    }
  }

  statement {
    sid    = "VisualEditor1"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeAutoScalingGroups",
      "ec2:DescribeLaunchTemplateVersions",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeLaunchConfigurations",
      "ec2:DescribeInstanceTypes"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster-autoscaler-policy" {
  name = "${module.eks.cluster_name}-cluster-autoscaler-policy"

  policy = data.aws_iam_policy_document.cluster_autoscaler_policy.json
}

resource "aws_iam_role" "cluster-autoscaler-role" {
  name               = "${module.eks.cluster_name}-cluster-autoscaler-role"
  assume_role_policy = data.aws_iam_policy_document.clusterautoscaler-role-policy.json
}
resource "aws_iam_role_policy_attachment" "cluster-autoscaler-attach" {
  role       = aws_iam_role.cluster-autoscaler-role.name
  policy_arn = aws_iam_policy.cluster-autoscaler-policy.arn
}