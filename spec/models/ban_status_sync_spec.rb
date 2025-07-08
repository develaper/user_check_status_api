require 'rails_helper'

RSpec.describe 'BanStatus synchronization', type: :model do
  describe 'User and IntegrityLog ban_status enums' do
    it 'should have identical ban_status enum values' do
      expect(User.ban_statuses).to eq(IntegrityLog.ban_statuses)
    end
    
    it 'should support all defined ban statuses' do
      User.ban_statuses.each do |status, value|
        user = build(:user, ban_status: status)
        expect(user).to be_valid
        expect(user.ban_status).to eq(status.to_s)
        
        log = build(:integrity_log, ban_status: status)
        expect(log).to be_valid
        expect(log.ban_status).to eq(status.to_s)
      end
    end
    
    it 'should have the same enum options available' do
      expect(User.ban_status_options).to eq(IntegrityLog.ban_status_options)
    end
    
    it 'should maintain backwards compatibility' do
      # These are the original statuses that must always exist
      required_statuses = [:not_banned, :banned]
      
      required_statuses.each do |status|
        expect(User.ban_statuses).to have_key(status.to_s)
        expect(IntegrityLog.ban_statuses).to have_key(status.to_s)
      end
    end
  end
  
  describe 'BanStatusEnum concern' do
    it 'provides the same enum values to both models' do
      expect(User.ban_status_values).to eq(IntegrityLog.ban_status_values)
    end
    
    it 'provides helper methods' do
      expect(User).to respond_to(:ban_status_values)
      expect(User).to respond_to(:ban_status_options)
      expect(IntegrityLog).to respond_to(:ban_status_values)
      expect(IntegrityLog).to respond_to(:ban_status_options)
    end
  end
end
