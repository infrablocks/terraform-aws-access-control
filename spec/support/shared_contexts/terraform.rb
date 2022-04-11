# frozen_string_literal: true

require 'aws-sdk'
require 'awspec'
require 'ostruct'

require_relative '../terraform_module'

# rubocop:disable RSpec/ContextWording
shared_context 'terraform' do
  include Awspec::Helper::Finder

  # rubocop:disable Style/OpenStructUse
  let(:vars) do
    OpenStruct.new(
      TerraformModule.configuration
          .for(:harness)
          .vars
    )
  end
  # rubocop:enable Style/OpenStructUse

  def configuration
    TerraformModule.configuration
  end

  def output_for(role, name)
    TerraformModule.output_for(role, name)
  end

  def reprovision(overrides = nil)
    TerraformModule.provision_for(
      :harness,
      TerraformModule.configuration.for(:harness, overrides).vars
    )
  end
end
# rubocop:enable RSpec/ContextWording
