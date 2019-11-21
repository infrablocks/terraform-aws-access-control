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
//
//resource "aws_iam_group_policy_attachment" "policies" {
//  for_each = toset(var.group_policies)
//  group = aws_iam_group.group.name
//  policy_arn = each.value
//}

locals {
  group_attributes = [
    for group in var.groups :
      {
        name = aws_iam_group.group[index(var.groups, group)].name,
        arn = aws_iam_group.group[index(var.groups, group)].arn,
      }
  ]
}
