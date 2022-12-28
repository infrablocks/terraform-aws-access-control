output "users" {
  description = "Details of the managed users."
  value = local.user_attributes
}

output "groups" {
  description = "Details of the managed groups."
  value = local.group_attributes
}
