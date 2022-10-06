# frozen_string_literal: true

require 'spec_helper'

describe 'groups' do
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

      @plan = plan(role: :root) do |vars|
        vars.groups = [
          group(
            name: @group_name,
            users: @group_users,
            policies: @group_policies
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

      @plan = plan(role: :root) do |vars|
        vars.groups = [
          group(name: @group_1_name, users: @group_1_users),
          group(name: @group_2_name, users: @group_2_users),
          group(name: @group_3_name, users: @group_3_users)
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
  end

  # it 'adds all required policies to each group' do
  #   requested_groups.each do |requested_group|
  #     requested_group[:policies].each do |requested_policy_arn|
  #       expect(@plan)
  #         .to(include_resource_creation(
  #           type: 'aws_iam_group_policy_attachment'
  #         )
  #               .with_attribute_value(:group, requested_group[:name])
  #               .with_attribute_value(:policy_arn, requested_policy_arn))
  #     end
  #   end
  # end
  #
  # it 'creates an assumable roles policy for each group' do
  #   requested_groups.each do |requested_group|
  #     expect(@plan)
  #       .to(include_resource_creation(type: 'aws_iam_policy')
  #             .with_attribute_value(
  #               :name, "#{requested_group[:name]}-assumable-roles-policy"
  #             )
  #             .with_attribute_value(
  #               :policy,
  #               a_policy_with_statement(
  #                 Effect: 'Allow',
  #                 Action: 'sts:AssumeRole',
  #                 Resource: assumable_role_arns
  #               )
  #             ))
  #   end
  # end

  def group(overrides = {})
    {
      name: "group-#{SecureRandom.alphanumeric(4)}",
      users: [],
      policies: [],
      assumable_roles: []
    }.merge(overrides)
  end
end
