# This should use multiple instances of infrablocks/terraform-aws-user but since
# terraform doesn't support count or for_each on modules yet, we have to copy
# the contents here
locals {
  users_needing_enforced_mfa = [
    for user in var.users : user if user.enforce_mfa == "yes" && user.enabled == "yes"
  ]
}

data "aws_caller_identity" "current" {}

resource "aws_iam_user_policy_attachment" "iam_read_only" {
  count = length(local.enabled_users)
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  user = aws_iam_user.user[count.index].name
}

resource "aws_iam_user_policy_attachment" "manage_specific_credentials" {
  count = length(local.enabled_users)
  policy_arn = "arn:aws:iam::aws:policy/IAMSelfManageServiceSpecificCredentials"
  user = aws_iam_user.user[count.index].name
}

resource "aws_iam_user_policy_attachment" "manage_ssh_keys" {
  count = length(local.enabled_users)
  policy_arn = "arn:aws:iam::aws:policy/IAMUserSSHKeys"
  user = aws_iam_user.user[count.index].name
}

data "aws_iam_policy_document" "change_password" {
  count = length(local.enabled_users)

  statement {
    actions = [
      "iam:ChangePassword"
    ]
    resources = [
      aws_iam_user.user[count.index].arn
    ]
    sid = "AllowUserToChangeTheirPassword"
  }
  statement {
    actions = [
      "iam:GetAccountPasswordPolicy"
    ]
    resources = [
      "*"
    ]
    sid = "AllowUserToViewPasswordPolicy"
  }
}

resource "aws_iam_user_policy" "change_password" {
  count = length(local.enabled_users)

  name = "IAMUserChangeOwnPassword"
  user = aws_iam_user.user[count.index].name
  policy = data.aws_iam_policy_document.change_password[count.index].json
}

data "aws_iam_policy_document" "manage_mfa" {
  count = length(local.enabled_users)

  statement {
    actions = [
      "iam:*MFADevice"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/${aws_iam_user.user[count.index].name}",
      aws_iam_user.user[count.index].arn,
    ]
    sid = "AllowUserToManageTheirMFA"
  }
}

resource "aws_iam_user_policy" "manage_mfa" {
  count = length(local.enabled_users)

  name = "IAMUserManageOwnMFA"
  user = aws_iam_user.user[count.index].name
  policy = data.aws_iam_policy_document.manage_mfa[count.index].json
}

data "aws_iam_policy_document" "manage_profile" {
  count = length(local.enabled_users)

  statement {
    actions = [
      "iam:*AccessKey*",
      "iam:*LoginProfile",
      "iam:*SigningCertificate*"
    ]
    resources = [
      aws_iam_user.user[count.index].arn
    ]
    sid = "AllowUserToManageOwnProfile"
  }
}

resource "aws_iam_user_policy" "manage_profile" {
  count = length(local.enabled_users)

  name = "IAMUserManageOwnProfile"
  user = aws_iam_user.user[count.index].name
  policy = data.aws_iam_policy_document.manage_profile[count.index].json
}

data "aws_iam_policy_document" "enforce_mfa" {
  count = length(local.users_needing_enforced_mfa)

  statement {
    condition {
      test = "BoolIfExists"
      values = ["false"]
      variable = "aws:MultiFactorAuthPresent"
    }
    effect = "Deny"
    not_actions = [
      "iam:*LoginProfile",
      "iam:*MFADevice",
      "iam:ChangePassword",
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary",
      "iam:List*MFADevices",
      "iam:ListAccountAliases",
      "iam:ListUsers",
    ]
    resources = [
      "*",
    ]
    sid = "DenyEverythingOtherThanLoginManagementUnlessMFAd"
  }

  statement {
    condition {
      test = "BoolIfExists"
      values = ["false"]
      variable = "aws:MultiFactorAuthPresent"
    }
    effect = "Deny"
    actions = [
      "iam:*LoginProfile",
      "iam:*MFADevice",
      "iam:ChangePassword"
    ]
    not_resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/${aws_iam_user.user[index(local.enabled_users, local.users_needing_enforced_mfa[count.index])].name}",
      aws_iam_user.user[index(local.enabled_users, local.users_needing_enforced_mfa[count.index])].arn
    ]
    sid = "DenyIAMAccessToOtherUsersUnlessMFAd"
  }
}

resource "aws_iam_user_policy" "enforce_mfa" {
  count = length(local.users_needing_enforced_mfa)

  name = "EnforceMFA"
  policy = data.aws_iam_policy_document.enforce_mfa[count.index].json
  user = aws_iam_user.user[count.index].name
}
