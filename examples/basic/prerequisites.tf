data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    principals {
      identifiers = [
        data.aws_caller_identity.current.arn
      ]
      type = "AWS"
    }

    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "role_1" {
  name = "role-1-${var.deployment_identifier}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role" "role_2" {
  name = "role-2-${var.deployment_identifier}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role" "role_3" {
  name = "role-3-${var.deployment_identifier}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
