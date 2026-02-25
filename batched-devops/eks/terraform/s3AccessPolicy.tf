
data "aws_iam_policy_document" "s3_policy" {
  version = "2012-10-17"

  statement {
    sid    = "VisualEditor0"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:ListBucket",
    ]

    resources = flatten([
      for bucket_name in var.bucket_names : [
        "arn:aws:s3:::${bucket_name}/*",
        "arn:aws:s3:::${bucket_name}",
      ]
    ])
  }
  statement {
    sid       = "VisualEditor1"
    effect    = "Allow"
    actions   = ["ssm:GetParametersByPath"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "backend-api-s3_access_policy"
  description = "Policy for accessing S3 buckets"

  policy = data.aws_iam_policy_document.s3_policy.json
}