data "aws_iam_policy_document" "ebs-csi-driver-role-trust-policy" {
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

      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
      variable = "${module.eks.oidc_provider}:sub"
    }
  }
}

resource "aws_iam_role" "ebs-csi-driver-role" {
  name = "${module.eks.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = data.aws_iam_policy_document.ebs-csi-driver-role-trust-policy.json
}
resource "aws_iam_role_policy_attachment" "ebs-csi-driver-role-attach" {
  role       = aws_iam_role.ebs-csi-driver-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}