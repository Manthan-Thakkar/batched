data "aws_iam_policy_document" "eventbridge_access_policy_document" {
  statement {
    sid    = "VisualEditor0"
    effect = "Allow"

    actions = [
      "events:DeleteRule",
      "events:PutTargets",
      "events:EnableRule",
      "events:PutRule",
      "events:RemoveTargets",
      "events:DisableRule",
      "events:ListTargetsByRule",
      "events:ListRules"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "eventbridge_access_policy" {
  name   = "EventBridgeReadWritePolicy"
  policy = data.aws_iam_policy_document.eventbridge_access_policy_document.json
}