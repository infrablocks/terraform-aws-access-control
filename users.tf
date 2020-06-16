# This should use multiple instances of infrablocks/terraform-aws-user but since
# terraform doesn't support count or for_each on modules yet, we have to copy
# the contents here
locals {
  enabled_users = {
    for user in var.users : user.name => user if user.enabled == "yes"
  }
  users_needing_login_profile = {
    for user in var.users : user.name => user if user.include_login_profile == "yes" && user.enabled == "yes"
  }
  users_needing_access_key = {
    for user in var.users : user.name => user if user.include_access_key == "yes" && user.enabled == "yes"
  }
}

resource "aws_iam_user" "user" {
  for_each = local.enabled_users
  name = each.key
  force_destroy = true
}

resource "aws_iam_user_login_profile" "user" {
  for_each = local.users_needing_login_profile

  user = aws_iam_user.user[each.key].name
  pgp_key = each.value.public_gpg_key
  password_length = each.value.password_length
}

resource "aws_iam_access_key" "user" {
  for_each = local.users_needing_access_key

  user = aws_iam_user.user[each.key].name
  pgp_key = each.value.public_gpg_key
}

locals {
  user_attributes = [
    for user in var.users :
      {
        name = user.name,
        enabled = user.enabled,
        arn = contains(keys(local.enabled_users), user.name) ? aws_iam_user.user[user.name].arn : "",
        password = contains(keys(local.users_needing_login_profile), user.name) ? aws_iam_user_login_profile.user[user.name].encrypted_password : ""
        access_key_id = contains(keys(local.users_needing_access_key), user.name) ? aws_iam_access_key.user[user.name].id : ""
        secret_access_key = contains(keys(local.users_needing_access_key), user.name) ? aws_iam_access_key.user[user.name].encrypted_secret : ""
      }
  ]
}
