data "terraform_remote_state" "prerequisites" {
  backend = "local"

  config = {
    path = "${path.module}/../../../../state/prerequisites.tfstate"
  }
}

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
        assumable_roles = list(
          data.terraform_remote_state.prerequisites.outputs.test_role_1_arn,
          data.terraform_remote_state.prerequisites.outputs.test_role_2_arn,
          data.terraform_remote_state.prerequisites.outputs.test_role_3_arn,
        )
      }
  ]
}

module "access_control" {
  source = "../../../../"

  users = local.users
  groups = local.groups
}
