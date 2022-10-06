# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'
require 'base64'

describe 'users' do
  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [user, user]
        vars.groups = []
      end
    end

    it 'outputs details of the created users' do
      expect(@plan)
        .to(include_output_creation(name: 'users'))
    end
  end

  describe 'when user is enabled' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(name: 'test@example.com', enabled: 'yes')
        ]
        vars.groups = []
      end
    end

    it 'creates a user' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_iam_user')
              .with_attribute_value(:name, 'test@example.com'))
    end
  end

  describe 'when user is disabled' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(name: 'test@example.com', enabled: 'no')
        ]
        vars.groups = []
      end
    end

    it 'does not create a user' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_user')
              .with_attribute_value(:name, 'test@example.com'))
    end
  end

  describe 'when user is enabled and login profile included' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(
            name: 'test@example.com',
            password_length: 48,
            enabled: 'yes',
            include_login_profile: 'yes'
          )
        ]
        vars.groups = []
      end
    end

    it 'creates a login profile for the user' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_iam_user_login_profile')
              .with_attribute_value(:user, 'test@example.com'))
    end

    it 'uses the specified password length' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_iam_user_login_profile')
              .with_attribute_value(:user, 'test@example.com')
              .with_attribute_value(:password_length, 48))
    end

    it 'uses the specified public GPG key' do
      public_gpg_key_path = var(role: :root, name: 'user_public_gpg_key_path')
      public_gpg_key = Base64.strict_encode64(File.read(public_gpg_key_path))

      expect(@plan)
        .to(include_resource_creation(type: 'aws_iam_user_login_profile')
              .with_attribute_value(:user, 'test@example.com')
              .with_attribute_value(:pgp_key, public_gpg_key))
    end
  end

  describe 'when user is enabled and login profile not included' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(
            name: 'test@example.com',
            enabled: 'yes',
            include_login_profile: 'no'
          )
        ]
        vars.groups = []
      end
    end

    it 'does not create a login profile for the user' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_user_login_profile')
              .with_attribute_value(:user, 'test@example.com'))
    end
  end

  describe 'when user is disabled and login profile included' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(
            name: 'test@example.com',
            enabled: 'no',
            include_login_profile: 'yes'
          )
        ]
        vars.groups = []
      end
    end

    it 'does not create a login profile for the user' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_user_login_profile')
                  .with_attribute_value(:user, 'test@example.com'))
    end
  end

  describe 'when user is disabled and login profile not included' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(
            name: 'test@example.com',
            enabled: 'no',
            include_login_profile: 'no'
          )
        ]
        vars.groups = []
      end
    end

    it 'does not create a login profile for the user' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_user_login_profile')
                  .with_attribute_value(:user, 'test@example.com'))
    end
  end

  describe 'when user is enabled and access key included' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(
            name: 'test@example.com',
            password_length: 48,
            enabled: 'yes',
            include_access_key: 'yes'
          )
        ]
        vars.groups = []
      end
    end

    it 'creates an access key for the user' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_iam_access_key')
              .with_attribute_value(:user, 'test@example.com'))
    end

    it 'uses the specified public GPG key' do
      public_gpg_key_path = var(role: :root, name: 'user_public_gpg_key_path')
      public_gpg_key = Base64.strict_encode64(File.read(public_gpg_key_path))

      expect(@plan)
        .to(include_resource_creation(type: 'aws_iam_access_key')
              .with_attribute_value(:user, 'test@example.com')
              .with_attribute_value(:pgp_key, public_gpg_key))
    end
  end

  describe 'when user is enabled and access key not included' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(
            name: 'test@example.com',
            password_length: 48,
            enabled: 'yes',
            include_access_key: 'no'
          )
        ]
        vars.groups = []
      end
    end

    it 'does not create an access key for the user' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_access_key')
              .with_attribute_value(:user, 'test@example.com'))
    end
  end

  describe 'when user is disabled and access key included' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(
            name: 'test@example.com',
            password_length: 48,
            enabled: 'no',
            include_access_key: 'yes'
          )
        ]
        vars.groups = []
      end
    end

    it 'does not create an access key for the user' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_access_key')
                  .with_attribute_value(:user, 'test@example.com'))
    end
  end

  describe 'when user is disabled and access key not included' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = [
          user(
            name: 'test@example.com',
            password_length: 48,
            enabled: 'no',
            include_access_key: 'no'
          )
        ]
        vars.groups = []
      end
    end

    it 'does not create an access key for the user' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_access_key')
                  .with_attribute_value(:user, 'test@example.com'))
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
