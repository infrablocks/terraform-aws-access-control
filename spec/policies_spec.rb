require 'spec_helper'
require 'uri'
require 'json'

describe 'policies' do
  let(:requested_users) { vars.users }
  let(:output_users) { output_for(:harness, 'users', parse: true) }

  let(:account_id) { account.account }

  let(:requested_enabled_users) {
    requested_users
        .filter { |requested_user| requested_user[:enabled] == 'yes' }
  }

  it 'allows IAM read only access' do
    requested_enabled_users.each do |requested_user|
      created_user = iam_user(requested_user[:name])

      expect(created_user).to(have_iam_policy('IAMReadOnlyAccess'))
    end
  end

  it 'allows managing service specific credentials' do
    requested_enabled_users.each do |requested_user|
      created_user = iam_user(requested_user[:name])

      expect(created_user).to(have_iam_policy('IAMSelfManageServiceSpecificCredentials'))
    end
  end

  it 'allows managing user SSH keys' do
    requested_enabled_users.each do |requested_user|
      created_user = iam_user(requested_user[:name])

      expect(created_user).to(have_iam_policy('IAMUserSSHKeys'))
    end
  end

  it("allows managing MFA device without MFA in context") do
    requested_enabled_users.each do |requested_user|
      user_name = requested_user[:name]
      created_user = iam_user(user_name)

      expect(created_user)
          .to(be_allowed_action('iam:*MFADevice')
              .resource_arn("arn:aws:iam::#{account_id}:mfa/#{user_name}"))
      expect(created_user)
          .to(be_allowed_action('iam:*MFADevice')
              .resource_arn(created_user.arn))
      expect(created_user)
          .to(be_allowed_action('iam:List*MFADevices')
              .resource_arn('*'))
    end
  end

  it("allows managing user profile without MFA in context") do
    requested_enabled_users.each do |requested_user|
      user_name = requested_user[:name]
      created_user = iam_user(user_name)

      expect(created_user)
          .to(be_allowed_action('iam:*LoginProfile')
              .resource_arn(created_user.arn))
    end
  end

  it('requires MFA in context to manage access keys and signing certs') do
    requested_enabled_users.each do |requested_user|
      user_name = requested_user[:name]
      created_user = iam_user(user_name)
      mfa_context = {
          context_key_name: "aws:MultiFactorAuthPresent",
          context_key_values: ["true"],
          context_key_type: "boolean"
      }
      expect(created_user)
          .not_to(be_allowed_action('iam:*AccessKey*')
              .resource_arn(created_user.arn))
      expect(created_user)
          .not_to(be_allowed_action('iam:*SigningCertificate*')
              .resource_arn(created_user.arn))
      expect(created_user)
          .to(be_allowed_action('iam:*AccessKey*')
              .resource_arn(created_user.arn)
              .context_entries([mfa_context]))
      expect(created_user)
          .to(be_allowed_action('iam:*SigningCertificate*')
              .resource_arn(created_user.arn)
              .context_entries([mfa_context]))
    end
  end

  it('allows changing password without MFA in context') do
    requested_enabled_users.each do |requested_user|
      user_name = requested_user[:name]
      created_user = iam_user(user_name)

      expect(created_user)
          .to(be_allowed_action('iam:GetAccountPasswordPolicy'))
      expect(created_user)
          .to(be_allowed_action('iam:ChangePassword')
              .resource_arn(created_user.arn))
    end
  end

  it('allows getting account summary without MFA in context') do
    requested_enabled_users.each do |requested_user|
      user_name = requested_user[:name]
      created_user = iam_user(user_name)

      expect(created_user).to(be_allowed_action('iam:GetAccountSummary'))
    end
  end

  it('allows users to be listed without MFA in context') do
    requested_enabled_users.each do |requested_user|
      user_name = requested_user[:name]
      created_user = iam_user(user_name)

      expect(created_user).to(be_allowed_action('iam:ListUsers'))
    end
  end

  it('allows account aliases to be listed without MFA in context') do
    requested_enabled_users.each do |requested_user|
      user_name = requested_user[:name]
      created_user = iam_user(user_name)

      expect(created_user).to(be_allowed_action('iam:ListAccountAliases'))
    end
  end
end
