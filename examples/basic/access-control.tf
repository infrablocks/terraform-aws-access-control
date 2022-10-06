locals {
  users = [
    for user in var.users :
      {
        name = user.name,
        password_length = user.password_length,
        public_gpg_key = filebase64(user.public_gpg_key_path),
        enforce_mfa = user.enforce_mfa,
        include_login_profile = user.include_login_profile,
        include_access_key = user.include_access_key,
        enabled = user.enabled
      }
  ]

  groups = [
    for group in var.groups :
      {
        name = group.name
        users = group.users
        policies = group.policies
        assumable_roles = [
          aws_iam_role.role_1.arn,
          aws_iam_role.role_2.arn,
          aws_iam_role.role_3.arn,
        ]
      }
  ]
}

module "access_control" {
  source = "../../"

  users = local.users
  groups = local.groups
}
