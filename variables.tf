variable "users" {
  description = "The list of users to manage."
  type = list(object({
    name = string,
    password_length = number,

    public_gpg_key = string,

    enforce_mfa = string,
    include_login_profile = string,
    include_access_key = string,

    enabled = string
  }))
}

variable "groups" {
  description = "The list of groups to manage."
  type = list(object({
    name = string
    users = list(string)
    policies = list(string)
    assumable_roles = list(string)
  }))
}
