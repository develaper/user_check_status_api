require 'rails_helper'

RSpec.describe IntegrityLog, type: :model do
  subject { build(:integrity_log) }
  
  describe 'validations' do
    it { should validate_presence_of(:idfa) }
    it { should validate_presence_of(:ban_status) }
    it { should validate_presence_of(:ip) }
    it { should validate_presence_of(:country) }
  end
  
  describe 'enums' do
    it { should define_enum_for(:ban_status).with_values(not_banned: 0, banned: 1) }
  end
  
  describe 'scopes' do
    let!(:user_log) { create(:integrity_log, idfa: 'test-idfa') }
    let!(:banned_log) { create(:banned_integrity_log) }
    let!(:not_banned_log) { create(:integrity_log, ban_status: :not_banned) }
    
    it 'filters by user idfa' do
      expect(IntegrityLog.for_user('test-idfa')).to include(user_log)
    end
    
    it 'filters banned logs' do
      expect(IntegrityLog.banned).to include(banned_log)
      expect(IntegrityLog.banned).not_to include(not_banned_log)
    end
    
    it 'filters not banned logs' do
      expect(IntegrityLog.not_banned).to include(not_banned_log)
      expect(IntegrityLog.not_banned).not_to include(banned_log)
    end
  end
  
  describe 'factory' do
    it 'creates a valid integrity log' do
      log = build(:integrity_log)
      expect(log).to be_valid
    end
    
    it 'creates a valid banned integrity log' do
      log = build(:banned_integrity_log)
      expect(log).to be_valid
      expect(log.ban_status).to eq('banned')
    end
    
    it 'creates a valid suspicious integrity log' do
      log = build(:suspicious_integrity_log)
      expect(log).to be_valid
      expect(log.rooted_device).to be true
      expect(log.proxy).to be true
      expect(log.vpn).to be true
    end
  end
end