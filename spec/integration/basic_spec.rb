# frozen_string_literal: true

require 'spec_helper'

describe 'basic' do
  before(:context) do
    apply(role: :basic)
  end

  after(:context) do
    destroy(
      role: :basic,
      only_if: -> { !ENV['FORCE_DESTROY'].nil? || ENV['SEED'].nil? }
    )
  end

  let(:defined_users) do
    [
      {
        name: 'test1@example.com',
        password_length: 32,

        enforce_mfa: 'no',
        include_login_profile: 'yes',
        include_access_key: 'no',

        enabled: 'yes'
      },
      {
        name: 'test2@example.com',
        password_length: 48,

        enforce_mfa: 'no',
        include_login_profile: 'no',
        include_access_key: 'yes',

        enabled: 'yes'
      },
      {
        name: 'test3@example.com',
        password_length: 64,

        enforce_mfa: 'yes',
        include_login_profile: 'yes',
        include_access_key: 'yes',

        enabled: 'no'
      },
      {
        name: 'test4@example.com',
        password_length: 64,

        enforce_mfa: 'yes',
        include_login_profile: 'no',
        include_access_key: 'yes',

        enabled: 'yes'
      }
    ]
  end

  let(:defined_groups) do
    [
      {
        name: 'group1',
        users: %w[test1@example.com test2@example.com],
        policies: %w[
          arn:aws:iam::aws:policy/ReadOnlyAccess
          arn:aws:iam::aws:policy/job-function/Billing
        ],
        assumable_roles: [
          output(role: :basic, name: 'role_1_arn'),
          output(role: :basic, name: 'role_3_arn')
        ]
      },
      {
        name: 'group2',
        users: %w[test2@example.com test4@example.com],
        policies: [
          'arn:aws:iam::aws:policy/job-function/Billing'
        ],
        assumable_roles: [
          output(role: :basic, name: 'role_2_arn'),
          output(role: :basic, name: 'role_3_arn')
        ]
      }
    ]
  end

  let(:output_users) do
    output(role: :basic, name: 'users')
  end

  let(:output_groups) do
    output(role: :basic, name: 'groups')
  end

  let(:account_id) { account.account }

  let(:gpg_key_passphrase) do
    File.read('config/secrets/user/gpg.passphrase')
  rescue StandardError
    nil
  end

  let(:private_gpg_key) do
    File.read('config/secrets/user/gpg.private')
  rescue StandardError
    nil
  end

  describe 'users' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'creates only enabled users' do
      defined_users.each do |defined_user|
        created_user = iam_user(defined_user[:name])
        output_user =
          output_users
          .select { |user| user[:name] == defined_user[:name] }
          .first

        if defined_user[:enabled] == 'yes'
          expect(created_user).to(exist)
          expect(created_user.arn).to(eq(output_user[:arn]))
        else
          expect(created_user).not_to(exist)
        end
      end
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'outputs usernames and GPG encrypted login passwords' do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .filter { |user| user[:include_login_profile] == 'yes' }
        .each do |defined_user|
        output_user =
          output_users
          .select { |user| user[:name] == defined_user[:name] }
          .first

        encrypted_password =
          StringIO.new(Base64.decode64(output_user[:password]))

        IOStreams::Pgp.import(key: private_gpg_key)
        password = IOStreams::Pgp::Reader
                   .open(encrypted_password,
                         passphrase: gpg_key_passphrase) do |stdout|
          stdout.read.chomp
        end

        expect(password&.length).to(be(defined_user[:password_length]))
      end
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'outputs access key IDs and secret access keys' do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .filter { |user| user[:include_access_key] == 'yes' }
        .each do |defined_user|
        output_user =
          output_users
          .select { |user| user[:name] == defined_user[:name] }
          .first

        access_key_id = output_user[:access_key_id]
        encrypted_secret_access_key =
          StringIO.new(Base64.decode64(output_user[:secret_access_key]))

        IOStreams::Pgp.import(key: private_gpg_key)
        secret_access_key =
          IOStreams::Pgp::Reader
          .open(encrypted_secret_access_key,
                passphrase: gpg_key_passphrase) do |stdout|
            stdout.read.chomp
          end

        expect(access_key_id.length).to(be(20))
        expect(secret_access_key&.length).to(be(40))
      end
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'groups' do
    # rubocop:disable RSpec/MultipleExpectations
    it 'creates all defined groups' do
      defined_groups.each do |defined_group|
        created_group = iam_group(defined_group[:name])
        output_group =
          output_groups
          .select { |group| group[:name] == defined_group[:name] }
          .first

        expect(created_group).to(exist)
        expect(created_group.arn).to(eq(output_group[:arn]))
      end
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'adds all required users to each group' do
      defined_groups.each do |defined_group|
        created_group = iam_group(defined_group[:name])

        expect(created_group.users.count)
          .to(eq(defined_group[:users].count))
        defined_group[:users].each do |defined_user|
          expect(created_group).to(have_iam_user(defined_user))
        end
      end
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'adds all required policies to each group' do
      defined_groups.each do |defined_group|
        created_group = iam_group(defined_group[:name])

        defined_group[:policies].each do |group_policy|
          expect(created_group).to(have_iam_policy(group_policy))
        end
      end
    end

    it 'can assume all assumable roles' do
      defined_groups.each do |defined_group|
        created_group = iam_group(defined_group[:name])

        defined_group[:assumable_roles].each do |assumable_role|
          expect(created_group)
            .to(be_allowed_action('sts:AssumeRole')
                  .resource_arn(assumable_role))
        end
      end
    end
  end

  describe 'policies' do
    it 'allows IAM read only access' do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .each do |defined_user|
        created_user = iam_user(defined_user[:name])

        expect(created_user).to(have_iam_policy('IAMReadOnlyAccess'))
      end
    end

    it 'allows managing service specific credentials' do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .each do |defined_user|
        created_user = iam_user(defined_user[:name])

        expect(created_user)
          .to(have_iam_policy('IAMSelfManageServiceSpecificCredentials'))
      end
    end

    it 'allows managing user SSH keys' do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .each do |defined_user|
        created_user = iam_user(defined_user[:name])

        expect(created_user).to(have_iam_policy('IAMUserSSHKeys'))
      end
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows managing MFA device without MFA in context' do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .each do |defined_user|
        user_name = defined_user[:name]
        created_user = iam_user(user_name)

        expect(created_user)
          .to(be_allowed_action('iam:*MFADevice')
                .resource_arn("arn:aws:iam::#{account_id}:mfa/*"))
        expect(created_user)
          .to(be_allowed_action('iam:*MFADevice')
                .resource_arn(created_user.arn))
        expect(created_user)
          .to(be_allowed_action('iam:List*MFADevices')
                .resource_arn('*'))
      end
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'allows managing user profile without MFA in context' do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .each do |defined_user|
        user_name = defined_user[:name]
        created_user = iam_user(user_name)

        expect(created_user)
          .to(be_allowed_action('iam:*LoginProfile')
                .resource_arn(created_user.arn))
      end
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'requires MFA in context to manage access keys and signing certs' do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .filter { |user| user[:enforce_mfa] == 'yes' }
        .each do |defined_user|
        user_name = defined_user[:name]
        created_user = iam_user(user_name)
        mfa_context = {
          context_key_name: 'aws:MultiFactorAuthPresent',
          context_key_values: ['true'],
          context_key_type: 'boolean'
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
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows changing password without MFA in context' do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .each do |defined_user|
        user_name = defined_user[:name]
        created_user = iam_user(user_name)

        expect(created_user)
          .to(be_allowed_action('iam:GetAccountPasswordPolicy'))
        expect(created_user)
          .to(be_allowed_action('iam:ChangePassword')
                .resource_arn(created_user.arn))
      end
    end
    # rubocop:enable RSpec/MultipleExpectations

    it('allows getting account summary without MFA in context') do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .each do |defined_user|
        user_name = defined_user[:name]
        created_user = iam_user(user_name)

        expect(created_user).to(be_allowed_action('iam:GetAccountSummary'))
      end
    end

    it('allows users to be listed without MFA in context') do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .each do |defined_user|
        user_name = defined_user[:name]
        created_user = iam_user(user_name)

        expect(created_user).to(be_allowed_action('iam:ListUsers'))
      end
    end

    it('allows account aliases to be listed without MFA in context') do
      defined_users
        .filter { |user| user[:enabled] == 'yes' }
        .each do |defined_user|
        user_name = defined_user[:name]
        created_user = iam_user(user_name)

        expect(created_user).to(be_allowed_action('iam:ListAccountAliases'))
      end
    end
  end
end
