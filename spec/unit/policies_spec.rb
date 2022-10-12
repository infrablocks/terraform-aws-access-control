# frozen_string_literal: true

require 'spec_helper'
require 'uri'
require 'json'

describe 'policies' do
  let(:iam_read_only_access_policy_arn) do
    'arn:aws:iam::aws:policy/IAMReadOnlyAccess'
  end
  let(:iam_self_manage_service_specific_credentials_policy_arn) do
    'arn:aws:iam::aws:policy/IAMSelfManageServiceSpecificCredentials'
  end
  let(:iam_user_ssh_keys_policy_arn) do
    'arn:aws:iam::aws:policy/IAMUserSSHKeys'
  end

  context 'when no users specified' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = []
        vars.groups = []
      end
    end

    it 'does not include any policy attachments for IAM read only access' do
      expect(@plan)
        .not_to(include_resource_creation(
          type: 'aws_iam_user_policy_attachment'
        )
                  .with_attribute_value(
                    :policy_arn, iam_read_only_access_policy_arn
                  ))
    end

    it 'does not include any policy attachments for managing IAM credentials' do
      expect(@plan)
        .not_to(include_resource_creation(
          type: 'aws_iam_user_policy_attachment'
        )
                  .with_attribute_value(
                    :policy_arn,
                    iam_self_manage_service_specific_credentials_policy_arn
                  ))
    end

    it 'does not include any policy attachments for managing SSH keys' do
      expect(@plan)
        .not_to(include_resource_creation(
          type: 'aws_iam_user_policy_attachment'
        )
                  .with_attribute_value(
                    :policy_arn, iam_user_ssh_keys_policy_arn
                  ))
    end

    it 'does not create any user policies' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_user_policy'))
    end
  end

  context 'when one user specified' do
    describe 'when the user is enabled' do
      before(:context) do
        client = Aws::STS::Client.new
        caller_id = client.get_caller_identity
        @account_id = caller_id.account

        @plan = plan(role: :root) do |vars|
          vars.users = [
            user(name: 'test@example.com', enabled: 'yes')
          ]
          vars.groups = []
        end
      end

      it 'creates a policy attachment for IAM read only access for the user' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy_arn, iam_read_only_access_policy_arn
                ))
      end

      it 'creates a policy attachment for for managing IAM credentials ' \
         'for the user' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy_arn,
                  iam_self_manage_service_specific_credentials_policy_arn
                ))
      end

      it 'creates a policy attachment for IAM SSH keys ' \
         'for the user' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy_arn,
                  iam_user_ssh_keys_policy_arn
                ))
      end

      it 'creates a user policy allowing the user to change their password' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'IAMUserChangeOwnPassword')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: 'iam:ChangePassword',
                    Resource:
                      "arn:aws:iam::#{@account_id}:user/test@example.com"
                  )
                ))
      end

      it 'creates a user policy allowing the user to manage their own ' \
         'profile' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'IAMUserManageOwnProfile')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: %w[
                      iam:*AccessKey*
                      iam:*LoginProfile
                      iam:*SigningCertificate*
                    ],
                    Resource:
                      "arn:aws:iam::#{@account_id}:user/test@example.com"
                  )
                ))
      end

      it 'creates a user policy allowing the user to manage their own MFA' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'IAMUserManageOwnMFA')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: 'iam:*MFADevice',
                    Resource: %W[
                      arn:aws:iam::#{@account_id}:mfa/test@example.com
                      arn:aws:iam::#{@account_id}:user/test@example.com
                    ]
                  )
                ))
      end
    end

    describe 'when the user is disabled' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.users = [
            user(name: 'test@example.com', enabled: 'no')
          ]
          vars.groups = []
        end
      end

      it 'does not create a policy attachment for IAM read only access ' \
         'for the user' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy_arn, iam_read_only_access_policy_arn
                ))
      end

      it 'does not create a policy attachment for managing IAM credentials ' \
         'for the user' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy_arn,
                  iam_self_manage_service_specific_credentials_policy_arn
                ))
      end

      it 'does not create a policy attachment for IAM SSH keys ' \
         'for the user' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy_arn,
                  iam_user_ssh_keys_policy_arn
                ))
      end

      it 'does not create a user policy allowing the user to change their ' \
         'password' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'IAMUserChangeOwnPassword')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: 'iam:ChangePassword',
                    Resource:
                      "arn:aws:iam::#{@account_id}:user/test@example.com"
                  )
                ))
      end

      it 'does not create a user policy allowing the user to manage their ' \
         'own profile' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'IAMUserManageOwnProfile')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: %w[
                      iam:*AccessKey*
                      iam:*LoginProfile
                      iam:*SigningCertificate*
                    ],
                    Resource:
                      "arn:aws:iam::#{@account_id}:user/test@example.com"
                  )
                ))
      end

      it 'does not create a user policy allowing the user to manage their ' \
         'own MFA' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'IAMUserManageOwnMFA')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: 'iam:*MFADevice',
                    Resource: %W[
                      arn:aws:iam::#{@account_id}:mfa/test@example.com
                      arn:aws:iam::#{@account_id}:user/test@example.com
                    ]
                  )
                ))
      end
    end

    describe 'when user should have MFA enforced and the user is enabled' do
      before(:context) do
        client = Aws::STS::Client.new
        caller_id = client.get_caller_identity
        @account_id = caller_id.account

        @plan = plan(role: :root) do |vars|
          vars.users = [
            user(name: 'test@example.com', enforce_mfa: 'yes', enabled: 'yes')
          ]
          vars.groups = []
        end
      end

      it 'creates a user policy preventing the user from doing anything ' \
         'other than manage their own IAM when the session was not ' \
         'established using MFA' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'EnforceMFA')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Deny',
                    NotAction: %w[
                      iam:*LoginProfile
                      iam:*MFADevice
                      iam:ChangePassword
                      iam:GetAccountPasswordPolicy
                      iam:GetAccountSummary
                      iam:List*MFADevices
                      iam:ListAccountAliases
                      iam:ListUsers
                    ],
                    Resource: '*',
                    Condition: {
                      BoolIfExists: {
                        'aws:MultiFactorAuthPresent': 'false'
                      }
                    }
                  )
                ))
      end

      it 'creates a user policy preventing the user from managing ' \
         'other users IAM credentials when the session was not ' \
         'established using MFA' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'EnforceMFA')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Deny',
                    Action: %w[
                      iam:*LoginProfile
                      iam:*MFADevice
                      iam:ChangePassword
                    ],
                    NotResource: %W[
                      arn:aws:iam::#{@account_id}:mfa/test@example.com
                      arn:aws:iam::#{@account_id}:user/test@example.com
                    ],
                    Condition: {
                      BoolIfExists: {
                        'aws:MultiFactorAuthPresent': 'false'
                      }
                    }
                  )
                ))
      end
    end

    describe 'when user should not have MFA enforced and the user is enabled' do
      before(:context) do
        client = Aws::STS::Client.new
        caller_id = client.get_caller_identity
        @account_id = caller_id.account

        @plan = plan(role: :root) do |vars|
          vars.users = [
            user(name: 'test@example.com', enforce_mfa: 'no', enabled: 'yes')
          ]
          vars.groups = []
        end
      end

      it 'does not create a user policy preventing the user from doing ' \
         'anything other than manage their own IAM when the session was not ' \
         'established using MFA' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'EnforceMFA')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Deny',
                    NotAction: %w[
                      iam:*LoginProfile
                      iam:*MFADevice
                      iam:ChangePassword
                      iam:GetAccountPasswordPolicy
                      iam:GetAccountSummary
                      iam:List*MFADevices
                      iam:ListAccountAliases
                      iam:ListUsers
                    ],
                    Resource: '*',
                    Condition: {
                      BoolIfExists: {
                        'aws:MultiFactorAuthPresent': 'false'
                      }
                    }
                  )
                ))
      end

      it 'does not create a user policy preventing the user from managing ' \
         'other users IAM credentials when the session was not ' \
         'established using MFA' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'EnforceMFA')
                .with_attribute_value(:user, 'test@example.com')
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Deny',
                    Action: %w[
                      iam:*LoginProfile
                      iam:*MFADevice
                      iam:ChangePassword
                    ],
                    NotResource: %W[
                      arn:aws:iam::#{@account_id}:mfa/test@example.com
                      arn:aws:iam::#{@account_id}:user/test@example.com
                    ],
                    Condition: {
                      BoolIfExists: {
                        'aws:MultiFactorAuthPresent': 'false'
                      }
                    }
                  )
                ))
      end
    end

    describe 'when user should have MFA enforced and the user is disabled' do
      before(:context) do
        client = Aws::STS::Client.new
        caller_id = client.get_caller_identity
        @account_id = caller_id.account

        @plan = plan(role: :root) do |vars|
          vars.users = [
            user(name: 'test@example.com', enforce_mfa: 'yes', enabled: 'no')
          ]
          vars.groups = []
        end
      end

      it 'does not create a user policy preventing the user from doing ' \
         'anything other than manage their own IAM when the session was not ' \
         'established using MFA' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                    .with_attribute_value(:name, 'EnforceMFA')
                    .with_attribute_value(:user, 'test@example.com')
                    .with_attribute_value(
                      :policy,
                      a_policy_with_statement(
                        Effect: 'Deny',
                        NotAction: %w[
                          iam:*LoginProfile
                          iam:*MFADevice
                          iam:ChangePassword
                          iam:GetAccountPasswordPolicy
                          iam:GetAccountSummary
                          iam:List*MFADevices
                          iam:ListAccountAliases
                          iam:ListUsers
                        ],
                        Resource: '*',
                        Condition: {
                          BoolIfExists: {
                            'aws:MultiFactorAuthPresent': 'false'
                          }
                        }
                      )
                    ))
      end

      it 'does not create a user policy preventing the user from managing ' \
         'other users IAM credentials when the session was not ' \
         'established using MFA' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                    .with_attribute_value(:name, 'EnforceMFA')
                    .with_attribute_value(:user, 'test@example.com')
                    .with_attribute_value(
                      :policy,
                      a_policy_with_statement(
                        Effect: 'Deny',
                        Action: %w[
                          iam:*LoginProfile
                          iam:*MFADevice
                          iam:ChangePassword
                        ],
                        NotResource: %W[
                          arn:aws:iam::#{@account_id}:mfa/test@example.com
                          arn:aws:iam::#{@account_id}:user/test@example.com
                        ],
                        Condition: {
                          BoolIfExists: {
                            'aws:MultiFactorAuthPresent': 'false'
                          }
                        }
                      )
                    ))
      end
    end

    describe 'when user should not have MFA enforced and the user is ' \
             'disabled' do
      before(:context) do
        client = Aws::STS::Client.new
        caller_id = client.get_caller_identity
        @account_id = caller_id.account

        @plan = plan(role: :root) do |vars|
          vars.users = [
            user(name: 'test@example.com', enforce_mfa: 'no', enabled: 'no')
          ]
          vars.groups = []
        end
      end

      it 'does not create a user policy preventing the user from doing ' \
         'anything other than manage their own IAM when the session was not ' \
         'established using MFA' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                    .with_attribute_value(:name, 'EnforceMFA')
                    .with_attribute_value(:user, 'test@example.com')
                    .with_attribute_value(
                      :policy,
                      a_policy_with_statement(
                        Effect: 'Deny',
                        NotAction: %w[
                          iam:*LoginProfile
                          iam:*MFADevice
                          iam:ChangePassword
                          iam:GetAccountPasswordPolicy
                          iam:GetAccountSummary
                          iam:List*MFADevices
                          iam:ListAccountAliases
                          iam:ListUsers
                        ],
                        Resource: '*',
                        Condition: {
                          BoolIfExists: {
                            'aws:MultiFactorAuthPresent': 'false'
                          }
                        }
                      )
                    ))
      end

      it 'does not create a user policy preventing the user from managing ' \
         'other users IAM credentials when the session was not ' \
         'established using MFA' do
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                    .with_attribute_value(:name, 'EnforceMFA')
                    .with_attribute_value(:user, 'test@example.com')
                    .with_attribute_value(
                      :policy,
                      a_policy_with_statement(
                        Effect: 'Deny',
                        Action: %w[
                          iam:*LoginProfile
                          iam:*MFADevice
                          iam:ChangePassword
                        ],
                        NotResource: %W[
                          arn:aws:iam::#{@account_id}:mfa/test@example.com
                          arn:aws:iam::#{@account_id}:user/test@example.com
                        ],
                        Condition: {
                          BoolIfExists: {
                            'aws:MultiFactorAuthPresent': 'false'
                          }
                        }
                      )
                    ))
      end
    end
  end

  context 'when many users specified' do
    before(:context) do
      client = Aws::STS::Client.new
      caller_id = client.get_caller_identity
      @account_id = caller_id.account

      @user1 = user(name: 'test1@example.com',
                    enabled: 'yes',
                    enforce_mfa: 'yes')
      @user2 = user(name: 'test2@example.com',
                    enabled: 'yes',
                    enforce_mfa: 'no')
      @user3 = user(name: 'test3@example.com',
                    enabled: 'no',
                    enforce_mfa: 'yes')
      @user4 = user(name: 'test4@example.com',
                    enabled: 'no',
                    enforce_mfa: 'no')

      @enabled_users = [@user1, @user2]
      @disabled_users = [@user3, @user4]

      @users_with_enforced_mfa = [@user1]
      @users_without_enforced_mfa = [@user2, @user3, @user4]

      @plan = plan(role: :root) do |vars|
        vars.users = [@user1, @user2, @user3, @user4]
        vars.groups = []
      end
    end

    it 'creates a policy attachment for IAM read only access for each ' \
       'enabled user' do
      @enabled_users.each do |user|
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy_arn, iam_read_only_access_policy_arn
                ))
      end
    end

    it 'does not create a policy attachment for IAM read only access for any ' \
       'disabled users' do
      @disabled_users.each do |user|
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                    .with_attribute_value(:user, user[:name])
                    .with_attribute_value(
                      :policy_arn, iam_read_only_access_policy_arn
                    ))
      end
    end

    it 'creates a policy attachment for managing IAM credentials ' \
       'for each enabled user' do
      @enabled_users.each do |user|
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy_arn,
                  iam_self_manage_service_specific_credentials_policy_arn
                ))
      end
    end

    it 'does not create a policy attachment for managing IAM credentials ' \
       'for any disabled users' do
      @disabled_users.each do |user|
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                    .with_attribute_value(:user, user[:name])
                    .with_attribute_value(
                      :policy_arn,
                      iam_self_manage_service_specific_credentials_policy_arn
                    ))
      end
    end

    it 'creates a policy attachment for IAM SSH keys ' \
       'for each enabled user' do
      @enabled_users.each do |user|
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy_arn,
                  iam_user_ssh_keys_policy_arn
                ))
      end
    end

    it 'does not create a policy attachment for IAM SSH keys ' \
       'for any disabled user' do
      @disabled_users.each do |user|
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy_attachment'
          )
                    .with_attribute_value(:user, user[:name])
                    .with_attribute_value(
                      :policy_arn,
                      iam_user_ssh_keys_policy_arn
                    ))
      end
    end

    it 'creates a user policy allowing all enabled users to change their ' \
       'password' do
      @enabled_users.each do |user|
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'IAMUserChangeOwnPassword')
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: 'iam:ChangePassword',
                    Resource: "arn:aws:iam::#{@account_id}:user/#{user[:name]}"
                  )
                ))
      end
    end

    it 'does not create a user policy allowing any disabled users to change ' \
       'their password' do
      @disabled_users.each do |user|
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                    .with_attribute_value(:name, 'IAMUserChangeOwnPassword')
                    .with_attribute_value(:user, user[:name])
                    .with_attribute_value(
                      :policy,
                      a_policy_with_statement(
                        Effect: 'Allow',
                        Action: 'iam:ChangePassword',
                        Resource:
                          "arn:aws:iam::#{@account_id}:user/#{user[:name]}"
                      )
                    ))
      end
    end

    it 'creates a user policy allowing each enabled user to manage their own ' \
       'profile' do
      @enabled_users.each do |user|
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'IAMUserManageOwnProfile')
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: %w[
                      iam:*AccessKey*
                      iam:*LoginProfile
                      iam:*SigningCertificate*
                    ],
                    Resource:
                      "arn:aws:iam::#{@account_id}:user/#{user[:name]}"
                  )
                ))
      end
    end

    it 'does not create a user policy allowing any disabled users to manage ' \
       'their own profile' do
      @disabled_users.each do |user|
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                    .with_attribute_value(:name, 'IAMUserManageOwnProfile')
                    .with_attribute_value(:user, user[:name])
                    .with_attribute_value(
                      :policy,
                      a_policy_with_statement(
                        Effect: 'Allow',
                        Action: %w[
                          iam:*AccessKey*
                          iam:*LoginProfile
                          iam:*SigningCertificate*
                        ],
                        Resource:
                          "arn:aws:iam::#{@account_id}:user/#{user[:name]}"
                      )
                    ))
      end
    end

    it 'creates a user policy allowing each enabled user to manage their ' \
       'own MFA' do
      @enabled_users.each do |user|
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'IAMUserManageOwnMFA')
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: 'iam:*MFADevice',
                    Resource: %W[
                      arn:aws:iam::#{@account_id}:mfa/#{user[:name]}
                      arn:aws:iam::#{@account_id}:user/#{user[:name]}
                    ]
                  )
                ))
      end
    end

    it 'does not create a user policy allowing any disabled user to manage ' \
       'their own MFA' do
      @disabled_users.each do |user|
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                    .with_attribute_value(:name, 'IAMUserManageOwnMFA')
                    .with_attribute_value(:user, user[:name])
                    .with_attribute_value(
                      :policy,
                      a_policy_with_statement(
                        Effect: 'Allow',
                        Action: 'iam:*MFADevice',
                        Resource: %W[
                          arn:aws:iam::#{@account_id}:mfa/#{user[:name]}
                          arn:aws:iam::#{@account_id}:user/#{user[:name]}
                        ]
                      )
                    ))
      end
    end

    it 'creates a user policy preventing each user with enforced MFA from ' \
       'doing anything other than manage their own IAM when the session was ' \
       'not established using MFA' do
      @users_with_enforced_mfa.each do |user|
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'EnforceMFA')
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Deny',
                    NotAction: %w[
                      iam:*LoginProfile
                      iam:*MFADevice
                      iam:ChangePassword
                      iam:GetAccountPasswordPolicy
                      iam:GetAccountSummary
                      iam:List*MFADevices
                      iam:ListAccountAliases
                      iam:ListUsers
                    ],
                    Resource: '*',
                    Condition: {
                      BoolIfExists: {
                        'aws:MultiFactorAuthPresent': 'false'
                      }
                    }
                  )
                ))
      end
    end

    it 'does not create a user policy preventing any user without enforced ' \
       'MFA from doing anything other than manage their own IAM when the ' \
       'session was not established using MFA' do
      @users_without_enforced_mfa.each do |user|
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'EnforceMFA')
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Deny',
                    NotAction: %w[
                      iam:*LoginProfile
                      iam:*MFADevice
                      iam:ChangePassword
                      iam:GetAccountPasswordPolicy
                      iam:GetAccountSummary
                      iam:List*MFADevices
                      iam:ListAccountAliases
                      iam:ListUsers
                    ],
                    Resource: '*',
                    Condition: {
                      BoolIfExists: {
                        'aws:MultiFactorAuthPresent': 'false'
                      }
                    }
                  )
                ))
      end
    end

    it 'creates a user policy preventing each user with enforced MFA from ' \
       'managing other users IAM credentials when the session was not ' \
       'established using MFA' do
      @users_with_enforced_mfa.each do |user|
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'EnforceMFA')
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Deny',
                    Action: %w[
                      iam:*LoginProfile
                      iam:*MFADevice
                      iam:ChangePassword
                    ],
                    NotResource: %W[
                      arn:aws:iam::#{@account_id}:mfa/#{user[:name]}
                      arn:aws:iam::#{@account_id}:user/#{user[:name]}
                    ],
                    Condition: {
                      BoolIfExists: {
                        'aws:MultiFactorAuthPresent': 'false'
                      }
                    }
                  )
                ))
      end
    end

    it 'does not create a user policy preventing any user without enforced ' \
       'MFA from managing other users IAM credentials when the session was ' \
       'not established using MFA' do
      @users_without_enforced_mfa.each do |user|
        expect(@plan)
          .not_to(include_resource_creation(
            type: 'aws_iam_user_policy'
          )
                .with_attribute_value(:name, 'EnforceMFA')
                .with_attribute_value(:user, user[:name])
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Deny',
                    Action: %w[
                      iam:*LoginProfile
                      iam:*MFADevice
                      iam:ChangePassword
                    ],
                    NotResource: %W[
                      arn:aws:iam::#{@account_id}:mfa/#{user[:name]}
                      arn:aws:iam::#{@account_id}:user/#{user[:name]}
                    ],
                    Condition: {
                      BoolIfExists: {
                        'aws:MultiFactorAuthPresent': 'false'
                      }
                    }
                  )
                ))
      end
    end
  end

  def user(overrides = {})
    {
      name: "test-#{SecureRandom.alphanumeric(4)}@example.com",
      password_length: 32,
      enforce_mfa: 'no',
      include_login_profile: 'no',
      include_access_key: 'no',
      enabled: 'yes'
    }.merge(overrides)
  end
end
