require 'spec_helper'
require 'json'
require 'uri'

describe 'users' do
  let(:users) { vars.users }

  it 'should create all defined users' do
    users.each do |user|
      expect(iam_user(user[:name])).to(exist)
    end
  end
end
