require 'rails_helper'

RSpec.describe UserService, type: :service do
  let(:valid_user_params) do
    {
      idfa: SecureRandom.uuid,
      ban_status: :not_banned
    }
  end
  
  let(:request_context) do
    {
      ip: '192.168.1.100',
      rooted_device: false,
      country: 'US',
      proxy: false,
      vpn: false
    }
  end

  describe '.create_user' do
    context 'with valid parameters' do
      it 'creates a user successfully' do
        expect {
          result = UserService.create_user(valid_user_params, request_context)
          expect(result).to be_success
          expect(result.data).to be_a(User)
          expect(result.data.idfa).to eq(valid_user_params[:idfa])
        }.to change(User, :count).by(1)
      end
      
      it 'creates an integrity log' do
        expect {
          UserService.create_user(valid_user_params, request_context)
        }.to change(IntegrityLog, :count).by(1)
      end
      
      it 'passes request context to logging service' do
        expect(IntegrityLogService).to receive(:log_event)
          .with(an_instance_of(User), 'user_creation', {}, request_context)
        
        UserService.create_user(valid_user_params, request_context)
      end
    end
    
    context 'with invalid parameters' do
      let(:invalid_params) { { idfa: 'invalid-format' } }
      
      it 'returns failure result' do
        result = UserService.create_user(invalid_params, request_context)
        expect(result).to be_failure
        expect(result.errors).to be_present
      end
      
      it 'does not create a user' do
        expect {
          UserService.create_user(invalid_params, request_context)
        }.not_to change(User, :count)
      end
      
      it 'does not create an integrity log' do
        expect {
          UserService.create_user(invalid_params, request_context)
        }.not_to change(IntegrityLog, :count)
      end
    end
  end

  describe '.update_ban_status' do
    let(:user) { create(:user, ban_status: :not_banned) }
    
    context 'with valid ban status' do
      it 'updates ban status successfully' do
        result = UserService.update_ban_status(user, :banned, request_context)
        
        expect(result).to be_success
        expect(result.data.ban_status).to eq('banned')
        expect(user.reload.ban_status).to eq('banned')
      end
      
      it 'creates an integrity log for ban status change' do
        expect {
          UserService.update_ban_status(user, :banned, request_context)
        }.to change(IntegrityLog, :count).by(1)
      end
      
      it 'passes correct parameters to logging service' do
        expect(IntegrityLogService).to receive(:log_event)
          .with(user, 'ban_status_change', {
            old_ban_status: 'not_banned',
            new_ban_status: :banned
          }, request_context)
        
        UserService.update_ban_status(user, :banned, request_context)
      end
    end
    
    context 'with invalid ban status' do
      it 'returns failure result' do
        result = UserService.update_ban_status(user, :invalid_status, request_context)
        expect(result).to be_failure
        expect(result.errors).to include("Invalid ban status")
      end
      
      it 'does not update the user' do
        original_status = user.ban_status
        UserService.update_ban_status(user, :invalid_status, request_context)
        expect(user.reload.ban_status).to eq(original_status)
      end
    end
  end

  describe 'error handling' do
    let(:user) { create(:user) }
    
    it 'handles service errors gracefully' do
      allow(IntegrityLogService).to receive(:log_event).and_raise(StandardError, 'Logging failed')
      
      # Service should still succeed even if logging fails
      result = UserService.update_ban_status(user, :banned, request_context)
      expect(result).to be_success
      expect(user.reload.ban_status).to eq('banned')
    end
  end
end