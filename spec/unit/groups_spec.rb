# frozen_string_literal: true

require 'spec_helper'

describe 'groups' do
  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.users = []
        vars.groups = [group, group]
      end
    end

    it 'outputs details of the created users' do
      expect(@plan)
        .to(include_output_creation(name: 'groups'))
    end
  end

  context 'when no groups specified' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.groups = []
        vars.users = []
      end
    end

    it 'does not create any groups' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_group'))
    end

    it 'does not create any group memberships' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_group_membership'))
    end

    it 'does not create any group policy attachments' do
      expect(@plan)
        .not_to(include_resource_creation(
                  type: 'aws_iam_group_policy_attachment'
                ))
    end

    it 'does not create an assumable roles policy' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_iam_policy'))
    end
  end

  context 'when one group specified' do
    before(:context) do
      @group_name = 'test-group'
      @group_users = %w[
        test-user1@example.com
        test-user2@example.com
      ]
      @group_policies = %w[
        arn:aws:iam::aws:policy/ReadOnlyAccess
        arn:aws:iam::aws:policy/job-function/Billing
      ]
      @group_assumable_roles = [
        output(role: :prerequisites, name: 'test_role_1_arn'),
        output(role: :prerequisites, name: 'test_role_2_arn')
      ]

      @plan = plan(role: :root) do |vars|
        vars.groups = [
          group(
            name: @group_name,
            users: @group_users,
            policies: @group_policies,
            assumable_roles: @group_assumable_roles
          )
        ]
        vars.users = []
      end
    end

    it 'creates a group with the provided name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_iam_group')
              .with_attribute_value(:name, @group_name))
    end

    it 'makes all specified users members of the group' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_iam_group_membership')
              .with_attribute_value(:name, "#{@group_name}-membership")
              .with_attribute_value(:group, @group_name)
              .with_attribute_value(:users, @group_users))
    end

    it 'attaches all specified policies to the group' do
      @group_policies.each do |policy_arn|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_iam_group_policy_attachment')
                .with_attribute_value(:group, @group_name)
                .with_attribute_value(:policy_arn, policy_arn))
      end
    end

    it 'creates an assumable roles policy' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_iam_policy')
              .with_attribute_value(
                :name, "#{@group_name}-assumable-roles-policy"
              )
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  Effect: 'Allow',
                  Action: 'sts:AssumeRole',
                  Resource: @group_assumable_roles
                )
              ))
    end
  end

  context 'when many groups specified' do
    before(:context) do
      @group_1_name = 'test-group-1'
      @group_2_name = 'test-group-2'
      @group_3_name = 'test-group-3'

      @group_names = [@group_1_name, @group_2_name, @group_3_name]

      @group_1_users = %w[
        test-user1@example.com
        test-user2@example.com
      ]
      @group_2_users = %w[
        test-user2@example.com
        test-user3@example.com
      ]
      @group_3_users = %w[
        test-user4@example.com
      ]

      @group_users = {
        @group_1_name => @group_1_users,
        @group_2_name => @group_2_users,
        @group_3_name => @group_3_users
      }

      @group_1_policies = %w[
        arn:aws:iam::aws:policy/ReadOnlyAccess
        arn:aws:iam::aws:policy/job-function/Billing
      ]
      @group_2_policies = %w[
        arn:aws:iam::aws:policy/ReadOnlyAccess
      ]
      @group_3_policies = []

      @group_policies = {
        @group_1_name => @group_1_policies,
        @group_2_name => @group_2_policies,
        @group_3_name => @group_3_policies
      }

      @group_1_assumable_roles = [
        output(role: :prerequisites, name: 'test_role_1_arn'),
        output(role: :prerequisites, name: 'test_role_2_arn')
      ]
      @group_2_assumable_roles = [
        output(role: :prerequisites, name: 'test_role_2_arn'),
        output(role: :prerequisites, name: 'test_role_3_arn')
      ]
      @group_3_assumable_roles = [
        output(role: :prerequisites, name: 'test_role_1_arn'),
        output(role: :prerequisites, name: 'test_role_3_arn')
      ]

      @group_assumable_roles = {
        @group_1_name => @group_1_assumable_roles,
        @group_2_name => @group_2_assumable_roles,
        @group_3_name => @group_3_assumable_roles
      }

      @plan = plan(role: :root) do |vars|
        vars.groups = [
          group(name: @group_1_name,
                users: @group_1_users,
                policies: @group_1_policies,
                assumable_roles: @group_1_assumable_roles),
          group(name: @group_2_name,
                users: @group_2_users,
                policies: @group_2_policies,
                assumable_roles: @group_2_assumable_roles),
          group(name: @group_3_name,
                users: @group_3_users,
                policies: @group_3_policies,
                assumable_roles: @group_3_assumable_roles)
        ]
        vars.users = []
      end
    end

    it 'creates a group for each specified with the correct name' do
      @group_names.each do |group_name|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_iam_group')
                .with_attribute_value(:name, group_name))
      end
    end

    it 'makes specified users members of each respective group' do
      @group_names.each do |group_name|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_iam_group_membership')
                .with_attribute_value(:name, "#{group_name}-membership")
                .with_attribute_value(:group, group_name)
                .with_attribute_value(:users, @group_users[group_name]))
      end
    end

    it 'attaches specified policies to each group' do
      @group_names.each do |group_name|
        @group_policies[group_name].each do |policy_arn|
          expect(@plan)
            .to(include_resource_creation(
              type: 'aws_iam_group_policy_attachment'
            )
                  .with_attribute_value(:group, group_name)
                  .with_attribute_value(:policy_arn, policy_arn))
        end
      end
    end

    it 'creates an assumable roles policy for each group' do
      @group_names.each do |group_name|
        expect(@plan)
          .to(include_resource_creation(type: 'aws_iam_policy')
                .with_attribute_value(
                  :name, "#{group_name}-assumable-roles-policy"
                )
                .with_attribute_value(
                  :policy,
                  a_policy_with_statement(
                    Effect: 'Allow',
                    Action: 'sts:AssumeRole',
                    Resource: @group_assumable_roles[group_name]
                  )
                ))
      end
    end
  end

  def group(overrides = {})
    {
      name: "group-#{SecureRandom.alphanumeric(4)}",
      users: [],
      policies: [],
      assumable_roles: []
    }.merge(overrides)
  end
end
