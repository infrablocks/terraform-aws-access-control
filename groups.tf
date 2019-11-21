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

locals {
  group_attributes = [
    for group in var.groups :
      {
        name = aws_iam_group.group[index(var.groups, group)].name,
        arn = aws_iam_group.group[index(var.groups, group)].arn,
      }
  ]
}
