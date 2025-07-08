require 'rails_helper'

RSpec.describe V1::UsersController::InvalidRootedDeviceError do
  describe 'error message' do
    it 'has a consistent error message defined as a constant' do
      expect(described_class::MESSAGE).to eq('rooted_device parameter must be a boolean (true or false)')
    end

    it 'uses the constant message by default' do
      error = described_class.new
      expect(error.message).to eq(described_class::MESSAGE)
    end

    it 'allows custom message to be passed' do
      custom_message = 'Custom error message'
      error = described_class.new(custom_message)
      expect(error.message).to eq(custom_message)
    end

    it 'inherits from ActionController::BadRequest' do
      error = described_class.new
      expect(error).to be_a(ActionController::BadRequest)
    end
  end
end