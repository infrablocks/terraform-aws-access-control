require 'spec_helper'

describe 'user' do
  let(:requested_groups) { vars.groups }
  let(:output_groups) { output_for(:harness, 'groups') }

  let(:test_role_1_arn) { output_for(:prerequisites, 'test_role_1_arn') }
  let(:test_role_2_arn) { output_for(:prerequisites, 'test_role_2_arn') }
  let(:test_role_3_arn) { output_for(:prerequisites, 'test_role_3_arn') }

  let(:assumable_roles) do
    [test_role_1_arn, test_role_2_arn, test_role_3_arn]
  end

  it 'creates all defined groups' do
    requested_groups.each do |requested_group|
      created_group = iam_group(requested_group[:name])
      output_group = output_groups
          .select { |output_group|
            output_group[:name] == requested_group[:name]
          }
          .first

      expect(created_group).to(exist)
      expect(created_group.arn).to(eq(output_group[:arn]))
    end
  end

  it 'adds all required users to each group' do
    requested_groups.each do |requested_group|
      created_group = iam_group(requested_group[:name])

      expect(created_group.users.count)
          .to(eq(requested_group[:users].count))
      requested_group[:users].each do |requested_user|
        expect(created_group).to(have_iam_user(requested_user))
      end
    end
  end

  it 'adds all required policies to each group' do
    requested_groups.each do |requested_group|
      created_group = iam_group(requested_group[:name])

      requested_group[:policies].each do |group_policy|
        expect(created_group).to(have_iam_policy(group_policy))
      end
    end
  end

  it 'can assume all assumable roles' do
    requested_groups.each do |requested_group|
      created_group = iam_group(requested_group[:name])

      assumable_roles.each do |assumable_role|
        expect(created_group)
            .to(be_allowed_action('sts:AssumeRole')
                .resource_arn(assumable_role))
      end
    end
  end
end
