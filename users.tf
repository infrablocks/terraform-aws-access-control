# This should use multiple instances of infrablocks/terraform-aws-user but since
# terraform doesn't support count or for_each on modules yet, we have to copy
# the contents here
locals {
  enabled_users = [
    for user in var.users : user if user.enabled == "yes"
  ]
  users_needing_login_profile = [
    for user in var.users : user if user.include_login_profile == "yes" && user.enabled == "yes"
  ]
  users_needing_access_key = [
    for user in var.users : user if user.include_access_key == "yes" && user.enabled == "yes"
  ]
}

resource "aws_iam_user" "user" {
  count = length(local.enabled_users)
  name = local.enabled_users[count.index].name
  force_destroy = true
}

resource "aws_iam_user_login_profile" "user" {
  count = length(local.users_needing_login_profile)

  user = aws_iam_user.user[index(local.enabled_users, local.users_needing_login_profile[count.index])].name
  pgp_key = local.users_needing_login_profile[count.index].public_gpg_key
  password_length = local.users_needing_login_profile[count.index].password_length
}

resource "aws_iam_access_key" "user" {
  count = length(local.users_needing_access_key)

  user = aws_iam_user.user[index(local.enabled_users, local.users_needing_access_key[count.index])].name
  pgp_key = local.users_needing_access_key[count.index].public_gpg_key
}

locals {
  user_attributes = [
    for user in var.users :
      {
        name = user.name,
        enabled = user.enabled,
        arn = contains(local.enabled_users, user) ? aws_iam_user.user[index(local.enabled_users, user)].arn : "",
        password = contains(local.users_needing_login_profile, user) ? aws_iam_user_login_profile.user[index(local.users_needing_login_profile, user)].encrypted_password : ""
        access_key_id = contains(local.users_needing_access_key, user) ? aws_iam_access_key.user[index(local.users_needing_access_key, user)].id : ""
        secret_access_key = contains(local.users_needing_access_key, user) ? aws_iam_access_key.user[index(local.users_needing_access_key, user)].encrypted_secret : ""
      }
  ]
}
