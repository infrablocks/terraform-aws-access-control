require 'spec_helper'
require 'json'
require 'uri'
require 'iostreams'

require_relative 'iostreams/pgp'

describe 'users' do
  let(:requested_users) { vars.users }
  let(:output_users) { output_for(:harness, 'users', parse: true) }

  it 'creates only enabled users' do
    requested_users.each do |requested_user|
      created_user = iam_user(requested_user[:name])
      output_user = output_users
          .select { |output_user|
            output_user[:name] == requested_user[:name]
          }
          .first

      if requested_user[:enabled] == 'yes'
        expect(created_user).to(exist)
        expect(created_user.arn).to(eq(output_user[:arn]))
      else
        expect(created_user).not_to(exist)
      end
    end
  end

  it 'outputs usernames and GPG encrypted login passwords' do
    requested_users
        .filter { |requested_user| requested_user[:enabled] == 'yes' }
        .each do |requested_user|
      output_user = output_users
          .select { |output_user|
            output_user[:name] == requested_user[:name]
          }
          .first

      encrypted_password =
          StringIO.new(
              Base64.decode64(
                  output_user[:password]))

      passphrase = configuration.gpg_key_passphrase
      private_key = File.read(configuration.private_gpg_key_path)

      IOStreams::Pgp.import(key: private_key)
      password = IOStreams::Pgp::Reader
          .open(encrypted_password, passphrase: passphrase) do |stdout|
        stdout.read.chomp
      end

      expect(password.length).to(be(requested_user[:password_length]))
    end
  end

  it 'outputs access key IDs and secret access keys' do
    requested_users
        .filter { |requested_user| requested_user[:enabled] == 'yes' }
        .each do |requested_user|
      output_user = output_users
          .select { |output_user|
            output_user[:name] == requested_user[:name]
          }
          .first

      access_key_id = output_user[:access_key_id]
      encrypted_secret_access_key =
          StringIO.new(
              Base64.decode64(
                  output_user[:secret_access_key]))

      passphrase = configuration.gpg_key_passphrase
      private_key = File.read(configuration.private_gpg_key_path)

      IOStreams::Pgp.import(key: private_key)
      secret_access_key = IOStreams::Pgp::Reader
          .open(encrypted_secret_access_key, passphrase: passphrase) do |stdout|
        stdout.read.chomp
      end

      expect(access_key_id.length).to(be(20))
      expect(secret_access_key.length).to(be(40))
    end
  end
end
