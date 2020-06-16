locals {
  groups = {
    for group in var.groups: group.name => group
  }
  # https://github.com/hashicorp/terraform/issues/22404
  group_policies = merge(flatten([[
    for group in var.groups:
      {
        for policy in group.policies:
          "${group.name}-${sha1(policy)}" => {
            group: group,
            policy_arn: policy
          }
      }
  ]])...)
  group_assumable_roles = {
    for group in var.groups:
      group.name => {
        group: group,
        assumable_roles: group.assumable_roles
      } if length(group.assumable_roles) > 0
  }
}

resource "aws_iam_group" "group" {
  for_each = local.groups
  name = each.key
}

resource "aws_iam_group_membership" "group" {
  for_each = local.groups
  name = "${each.key}-membership"
  group = aws_iam_group.group[each.key].name
  users = each.value.users
  depends_on = [aws_iam_user.user]
}

resource "aws_iam_group_policy_attachment" "policies" {
  for_each = local.group_policies
  group = aws_iam_group.group[each.value.group.name].name
  policy_arn = each.value.policy_arn
}

data "aws_iam_policy_document" "assumable_roles_policy" {
  for_each = local.group_assumable_roles

  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    resources = each.value.assumable_roles
  }
}

resource "aws_iam_policy" "assumable_roles_policy" {
  for_each = local.group_assumable_roles

  name = "${each.key}-assumable-roles-policy"
  policy = data.aws_iam_policy_document.assumable_roles_policy[each.key].json
}

resource "aws_iam_group_policy_attachment" "assumable_roles_policy" {
  for_each = local.group_assumable_roles
  group = aws_iam_group.group[each.key].name
  policy_arn = aws_iam_policy.assumable_roles_policy[each.key].arn
}

locals {
  group_attributes = [
    for group in var.groups :
      {
        name = aws_iam_group.group[group.name].name,
        arn = aws_iam_group.group[group.name].arn,
        policies = group.policies,
        assumable_roles = group.assumable_roles,
      }
  ]
}
