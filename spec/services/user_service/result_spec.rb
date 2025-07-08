require 'rails_helper'

RSpec.describe UserService::Result, type: :service do
  describe '.success' do
    let(:data) { { id: 1, name: 'Test User' } }
    let(:result) { UserService::Result.success(data) }

    it 'creates a successful result' do
      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.data).to eq(data)
      expect(result.errors).to be_nil
    end
  end

  describe '.failure' do
    let(:errors) { ['Invalid name', 'Email required'] }
    let(:result) { UserService::Result.failure(errors) }

    it 'creates a failure result' do
      expect(result).to be_failure
      expect(result).not_to be_success
      expect(result.errors).to eq(errors)
      expect(result.data).to be_nil
    end
  end

  describe 'namespace' do
    it 'is properly namespaced under UserService' do
      result = UserService::Result.success('test')
      expect(result.class.name).to eq('UserService::Result')
    end
  end
end