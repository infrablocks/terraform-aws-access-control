require 'spec_helper'

describe 'user' do
  let(:requested_groups) { vars.groups }
  let(:output_groups) { output_for(:harness, 'groups', parse: true) }

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

      expect(created_group.users.count).to(eq(requested_group[:users].count))
      requested_group[:users].each do |requested_user|
        expect(created_group).to(have_iam_user(requested_user))
      end
    end
  end

  # it 'has specified group policies' do
  #   group_policies.each do |group_policy|
  #     expect(subject).to(have_iam_policy(group_policy))
  #   end
  # end
end
