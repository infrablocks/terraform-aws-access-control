output "users" {
  value = module.access_control.users
}

output "groups" {
  value = module.access_control.groups
}

output "role_1_arn" {
  value = aws_iam_role.role_1.arn
}
output "role_2_arn" {
  value = aws_iam_role.role_2.arn
}
output "role_3_arn" {
  value = aws_iam_role.role_3.arn
}
