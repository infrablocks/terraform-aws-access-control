locals {
  group_policies = flatten([
    for group in var.groups:
      [
        for policy in group.policies:
          {
            group: group
            policy_arn: policy
          }
      ]
  ])
  group_assumable_roles = flatten([
    for group in var.groups:
      {
        name: group.name,
        assumable_roles: group.assumable_roles
      } if length(group.assumable_roles) > 0
  ])
}

resource "aws_iam_group" "group" {
  count = length(var.groups)
  name = var.groups[count.index].name
}

resource "aws_iam_group_membership" "group" {
  count = length(var.groups)
  name = "${var.groups[count.index].name}-membership"
  group = aws_iam_group.group[count.index].name
  users = var.groups[count.index].users
}

resource "aws_iam_group_policy_attachment" "policies" {
  count = length(local.group_policies)
  group = aws_iam_group.group[index(var.groups, local.group_policies[count.index].group)].name
  policy_arn = local.group_policies[count.index].policy_arn
}

data "aws_iam_policy_document" "assumable_roles_policy" {
  count = length(local.group_assumable_roles)

  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    resources = local.group_assumable_roles[count.index].assumable_roles
  }
}

resource "aws_iam_policy" "assumable_roles_policy" {
  count = length(local.group_assumable_roles)

  name = "${local.group_assumable_roles[count.index].name}-assumable-roles-policy"
  policy = data.aws_iam_policy_document.assumable_roles_policy[count.index].json
}

resource "aws_iam_group_policy_attachment" "assumable_roles_policy" {
  count = length(local.group_assumable_roles)
  group = local.group_assumable_roles[count.index].name
  policy_arn = aws_iam_policy.assumable_roles_policy[count.index].arn
}

locals {
  group_attributes = [
    for group in var.groups :
      {
        name = aws_iam_group.group[index(var.groups, group)].name,
        arn = aws_iam_group.group[index(var.groups, group)].arn,
        policies = group.policies,
        assumable_roles = group.assumable_roles,
      }
  ]
}
