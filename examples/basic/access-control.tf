locals {
  public_gpg_key = filebase64(var.public_gpg_key_path)

  users = [
    {
      name: "test1@example.com",
      password_length: 32,

      public_gpg_key = local.public_gpg_key,

      enforce_mfa: "no",
      include_login_profile: "yes",
      include_access_key: "no",

      enabled: "yes"
    },
    {
      name: "test2@example.com",
      password_length: 48,

      public_gpg_key = local.public_gpg_key,

      enforce_mfa: "no",
      include_login_profile: "no",
      include_access_key: "yes",

      enabled: "yes"
    },
    {
      name: "test3@example.com",
      password_length: 64,

      public_gpg_key = local.public_gpg_key,

      enforce_mfa: "yes",
      include_login_profile: "yes",
      include_access_key: "yes",

      enabled: "no"
    },
    {
      name: "test4@example.com",
      password_length: 64,

      public_gpg_key = local.public_gpg_key,

      enforce_mfa: "yes",
      include_login_profile: "no",
      include_access_key: "yes",

      enabled: "yes"
    }
  ]

  groups = [
    {
      name: "group1",
      users: [
        "test1@example.com",
        "test2@example.com"
      ],
      policies: [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
        "arn:aws:iam::aws:policy/job-function/Billing"
      ],
      assumable_roles = [
        aws_iam_role.role_1.arn,
        aws_iam_role.role_3.arn,
      ]
    },
    {
      name: "group2",
      users: [
        "test2@example.com",
        "test4@example.com"
      ],
      policies: [
        "arn:aws:iam::aws:policy/job-function/Billing"
      ],
      assumable_roles = [
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
