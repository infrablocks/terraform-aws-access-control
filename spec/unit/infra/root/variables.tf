variable "region" {}

variable "users" {
  type = list(object({
    name = string,
    password_length = number,

    enforce_mfa = string,
    include_login_profile = string,
    include_access_key = string,

    enabled = string
  }))
}

variable "groups" {
  type = list(object({
    name = string
    users = list(string)
    policies = list(string)
    assumable_roles = list(string)
  }))
}

variable "user_public_gpg_key_path" {}
