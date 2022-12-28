Terraform AWS Access Control
============================

[![Version](https://img.shields.io/github/v/tag/infrablocks/terraform-aws-access-control?label=version&sort=semver)](https://github.com/infrablocks/terraform-aws-access-control/tags)
[![Build Pipeline](https://img.shields.io/circleci/build/github/infrablocks/terraform-aws-access-control/main?label=build-pipeline)](https://app.circleci.com/pipelines/github/infrablocks/terraform-aws-access-control?filter=all)
[![Maintainer](https://img.shields.io/badge/maintainer-go--atomic.io-red)](https://go-atomic.io)

A Terraform module for configuring AWS account access control.

The access control deployment has no requirements.

The access control deployment consists of:

* A set of users, each having
    * a login profile (optional)
    * an access key (optional)
    * MFA enforced (optional)
* A set of group, each having
    * a set of users, defined above or otherwise
    * a set of attached policies
    * a set of assumable roles

Usage
-----

To use the module, include something like the following in your Terraform
configuration:

```terraform
module "access_control" {
  source  = "infrablocks/access-control/aws"
  version = "3.0.0"

  users = [
    {
      name            = "user@example.com"
      password_length = 32

      public_gpg_key = filebase64("${path.root}/keys/user.gpg")

      enforce_mfa           = "yes"
      include_login_profile = "yes"
      include_access_key    = "yes"

      enabled = "yes"
    }
  ]

  groups = [
    {
      name            = "admins"
      users           = ["user@example.com"]
      policies        = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      assumable_roles = []
    }
  ]
}
```

See the
[Terraform registry entry](https://registry.terraform.io/modules/infrablocks/access-control/aws/latest)
for more details.

### Inputs

| Name   | Description                   | Default | Required |
|--------|-------------------------------|:-------:|:--------:|
| users  | The list of users to manage.  |    -    |   yes    |
| groups | The list of groups to manage. |    -    |   yes    |

### Outputs

| Name   | Description                    |
|--------|--------------------------------|
| users  | Details of the managed users.  |
| groups | Details of the managed groups. |

### Compatibility

This module is compatible with Terraform versions greater than or equal to
Terraform 1.0.

Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed
on your development machine:

* Ruby (3.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv
* aws-vault

#### Mac OS X Setup

Installing the required tools is best managed by [homebrew](http://brew.sh).

To install homebrew:

```shell
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install the required tools:

```shell
# ruby
brew install rbenv
brew install ruby-build
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
eval "$(rbenv init -)"
rbenv install 3.1.1
rbenv rehash
rbenv local 3.1.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# aws-vault
brew cask install

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

Running the build requires an AWS account and AWS credentials. You are free to
configure credentials however you like as long as an access key ID and secret
access key are available. These instructions utilise
[aws-vault](https://github.com/99designs/aws-vault) which makes credential
management easy and secure.

To run the full build, including unit and integration tests, execute:

```shell
aws-vault exec <profile> -- ./go
```

To run the unit tests, execute:

```shell
aws-vault exec <profile> -- ./go test:unit
```

To run the integration tests, execute:

```shell
aws-vault exec <profile> -- ./go test:integration
```

To provision the module prerequisites:

```shell
aws-vault exec <profile> -- ./go deployment:prerequisites:provision[<deployment_identifier>]
```

To provision the module contents:

```shell
aws-vault exec <profile> -- ./go deployment:root:provision[<deployment_identifier>]
```

To destroy the module contents:

```shell
aws-vault exec <profile> -- ./go deployment:root:destroy[<deployment_identifier>]
```

To destroy the module prerequisites:

```shell
aws-vault exec <profile> -- ./go deployment:prerequisites:destroy[<deployment_identifier>]
```

Configuration parameters can be overridden via environment variables. For 
example, to run the unit tests with a seed of `"testing"`, execute:

```shell
SEED=testing aws-vault exec <profile> -- ./go test:unit
```

When a seed is provided via an environment variable, infrastructure will not be 
destroyed at the end of test execution. This can be useful during development 
to avoid lengthy provision and destroy cycles.

To subsequently destroy unit test infrastructure for a given seed:

```shell
FORCE_DESTROY=yes SEED=testing aws-vault exec <profile> -- ./go test:unit
```

### Common Tasks

#### Generating an SSH key pair

To generate an SSH key pair:

```
ssh-keygen -m PEM -t rsa -b 4096 -C integration-test@example.com -N '' -f config/secrets/keys/bastion/ssh
```

#### Generating a self-signed certificate

To generate a self signed certificate:

```
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
```

To decrypt the resulting key:

```
openssl rsa -in key.pem -out ssl.key
```

#### Managing CircleCI keys

To encrypt a GPG key for use by CircleCI:

```shell
openssl aes-256-cbc \
  -e \
  -md sha1 \
  -in ./config/secrets/ci/gpg.private \
  -out ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

To check decryption is working correctly:

```shell
openssl aes-256-cbc \
  -d \
  -md sha1 \
  -in ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at
https://github.com/infrablocks/terraform-aws-access-control.
This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

License
-------

The library is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
