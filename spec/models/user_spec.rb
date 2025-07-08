require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }
  
  describe 'validations' do
    it { should validate_presence_of(:idfa) }
    it { should validate_uniqueness_of(:idfa) }
    it { should validate_presence_of(:ban_status) }
    
    it 'validates idfa format' do
      user = build(:user, idfa: 'invalid-format')
      expect(user).to_not be_valid
      expect(user.errors[:idfa]).to include('must be a valid UUID format')
    end
    
    it 'accepts valid UUID format' do
      user = build(:user, idfa: '8264148c-be95-4b2b-b260-6ee98dd53bf6')
      expect(user).to be_valid
    end
  end
  
  describe 'enums' do
    it { should define_enum_for(:ban_status).with_values(not_banned: 0, banned: 1) }
  end
  
  describe 'factory' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end
    
    it 'creates a valid banned user' do
      user = build(:banned_user)
      expect(user).to be_valid
      expect(user.ban_status).to eq('banned')
    end
  end
end