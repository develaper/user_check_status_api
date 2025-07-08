require 'rails_helper'

RSpec.describe IntegrityLogService, type: :service do
  let(:user) { build(:user) }
  let(:request_data) do
    {
      ip: '192.168.1.100',
      rooted_device: true,
      country: 'US',
      proxy: false,
      vpn: true
    }
  end

  # Save user without callbacks to avoid interference
  before do
    user.save!(validate: false)
    # Reset to database data source for tests
    IntegrityLogService.configure_data_sources(:database)
  end
  
  after do
    # Reset to database data source
    IntegrityLogService.configure_data_sources(:database)
  end

  describe '.log_event' do
    it 'creates an integrity log with event information' do
      expect {
        IntegrityLogService.log_event(user, 'user_creation', {}, request_data)
      }.to change(IntegrityLog, :count).by(1)
    end

    it 'stores event information in additional_info' do
      log = IntegrityLogService.log_event(user, 'ban_status_change', {
        old_ban_status: 'not_banned',
        new_ban_status: 'banned'
      }, request_data)
      
      expect(log.additional_info['event_type']).to eq('ban_status_change')
      expect(log.additional_info['event_data']['old_ban_status']).to eq('not_banned')
      expect(log.additional_info['event_data']['new_ban_status']).to eq('banned')
      expect(log.additional_info['logged_at']).to be_present
    end
  end

  describe '.create_log_for_user' do
    it 'creates an integrity log' do
      expect {
        IntegrityLogService.create_log_for_user(user, request_data)
      }.to change(IntegrityLog, :count).by(1)
    end

    it 'creates an integrity log for the given user' do
      log = IntegrityLogService.create_log_for_user(user, request_data)
      expect(log.idfa).to eq(user.idfa)
    end

    it 'creates log with correct attributes' do
      log = IntegrityLogService.create_log_for_user(user, request_data)
      
      expect(log).to have_attributes(
        idfa: user.idfa,
        ban_status: user.ban_status,
        ip: request_data[:ip],
        rooted_device: request_data[:rooted_device],
        country: request_data[:country],
        proxy: request_data[:proxy],
        vpn: request_data[:vpn]
      )
    end

    it 'uses default values when request_data is empty' do
      log = IntegrityLogService.create_log_for_user(user, {})
      
      expect(log).to have_attributes(
        idfa: user.idfa,
        ban_status: user.ban_status,
        ip: 'Unknown',
        rooted_device: false,
        country: 'Unknown',
        proxy: false,
        vpn: false
      )
    end
  end

  describe 'data source configuration' do
    it 'allows configuring data sources' do
      IntegrityLogService.configure_data_sources(:database)
      expect(IntegrityLogService.log_data_sources).to eq([:database])
    end

    it 'allows adding data sources' do
      IntegrityLogService.add_data_source(:file)
      expect(IntegrityLogService.log_data_sources).to include(:file)
    end

    it 'allows removing data sources' do
      IntegrityLogService.configure_data_sources(:database, :file)
      IntegrityLogService.remove_data_source(:file)
      expect(IntegrityLogService.log_data_sources).not_to include(:file)
    end
  end

  describe 'error handling' do
    it 'continues with other data sources if one fails' do
      # Mock database data source to fail
      allow(IntegrityLogService).to receive(:write_to_database).and_raise(StandardError, 'Database error')
      
      expect(Rails.logger).to receive(:error).with(/Failed to write to database/)
      
      # Should not raise error
      expect {
        IntegrityLogService.create_log_for_user(user, request_data)
      }.not_to raise_error
    end
  end
end