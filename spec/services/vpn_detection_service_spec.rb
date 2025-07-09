require 'rails_helper'

RSpec.describe VpnDetectionService, type: :service do
  let(:test_ip) { '1.2.3.4' }
  
  before do
    allow(VpnCacheService).to receive(:get)
    allow(VpnCacheService).to receive(:set)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  describe '.ip_should_be_banned?' do
    context 'with blank IP' do
      it 'returns false for nil IP' do
        result = described_class.ip_should_be_banned?(nil)
        expect(result).to be false
      end

      it 'returns false for empty string IP' do
        result = described_class.ip_should_be_banned?('')
        expect(result).to be false
      end
    end

    context 'with cached results' do
      it 'returns cached banned result' do
        allow(VpnCacheService).to receive(:get).with(test_ip).and_return('banned')
        
        result = described_class.ip_should_be_banned?(test_ip)
        
        expect(result).to be true
        expect(VpnCacheService).to have_received(:get).with(test_ip)
        expect(VpnCacheService).not_to have_received(:set)
      end

      it 'returns cached allowed result' do
        allow(VpnCacheService).to receive(:get).with(test_ip).and_return('allowed')
        
        result = described_class.ip_should_be_banned?(test_ip)
        
        expect(result).to be false
        expect(VpnCacheService).to have_received(:get).with(test_ip)
        expect(VpnCacheService).not_to have_received(:set)
      end
    end

    context 'without cached results' do
      before do
        allow(VpnCacheService).to receive(:get).with(test_ip).and_return(nil)
      end

      context 'when VPNAPI_KEY is not configured' do
        before do
          allow(Rails.application.credentials).to receive(:vpnapi_key).and_return(nil)
        end

        it 'returns false (allows request)' do
          result = described_class.ip_should_be_banned?(test_ip)
          expect(result).to be false
        end

        it 'caches the allowed result' do
          described_class.ip_should_be_banned?(test_ip)
          expect(VpnCacheService).to have_received(:set).with(test_ip, 'allowed')
        end
      end

      context 'when VPNAPI_KEY is configured' do
        before do
          allow(Rails.application.credentials).to receive(:vpnapi_key).and_return('test_api_key')
        end

        context 'when API returns legitimate IP' do
          before do
            # Mock successful API response for legitimate IP
            response_body = {
              'security' => {
                'vpn' => false,
                'proxy' => false,
                'tor' => false,
                'relay' => false
              }
            }
            
            allow(HTTParty).to receive(:get).and_return(
              double('response', 
                success?: true, 
                code: 200, 
                parsed_response: response_body
              )
            )
          end

          it 'returns false (allows request)' do
            result = described_class.ip_should_be_banned?(test_ip)
            expect(result).to be false
          end

          it 'caches the allowed result' do
            described_class.ip_should_be_banned?(test_ip)
            expect(VpnCacheService).to have_received(:set).with(test_ip, 'allowed')
          end

          it 'makes API call with correct parameters' do
            expect(HTTParty).to receive(:get).with(
              "/api/#{test_ip}",
              query: { key: 'test_api_key' },
              timeout: 5,
              headers: { 'User-Agent' => 'Rails-Security-Check/1.0' }
            ).and_return(
              double('response', 
                success?: true, 
                code: 200, 
                parsed_response: {
                  'security' => {
                    'vpn' => false,
                    'proxy' => false,
                    'tor' => false,
                    'relay' => false
                  }
                }
              )
            )

            described_class.ip_should_be_banned?(test_ip)
          end
        end

        context 'when API returns VPN IP' do
          before do
            # Mock successful API response for VPN IP
            response_body = {
              'security' => {
                'vpn' => true,
                'proxy' => false,
                'tor' => false,
                'relay' => false
              }
            }
            
            allow(HTTParty).to receive(:get).and_return(
              double('response', 
                success?: true, 
                code: 200, 
                parsed_response: response_body
              )
            )
          end

          it 'returns true (bans request)' do
            result = described_class.ip_should_be_banned?(test_ip)
            expect(result).to be true
          end

          it 'caches the banned result' do
            described_class.ip_should_be_banned?(test_ip)
            expect(VpnCacheService).to have_received(:set).with(test_ip, 'banned')
          end
        end

        context 'when API returns Tor IP' do
          before do
            # Mock successful API response for Tor IP
            response_body = {
              'security' => {
                'vpn' => false,
                'proxy' => false,
                'tor' => true,
                'relay' => false
              }
            }
            
            allow(HTTParty).to receive(:get).and_return(
              double('response', 
                success?: true, 
                code: 200, 
                parsed_response: response_body
              )
            )
          end

          it 'returns true (bans request)' do
            result = described_class.ip_should_be_banned?(test_ip)
            expect(result).to be true
          end
        end

        context 'when API returns Proxy IP' do
          before do
            # Mock successful API response for Proxy IP
            response_body = {
              'security' => {
                'vpn' => false,
                'proxy' => true,
                'tor' => false,
                'relay' => false
              }
            }
            
            allow(HTTParty).to receive(:get).and_return(
              double('response', 
                success?: true, 
                code: 200, 
                parsed_response: response_body
              )
            )
          end

          it 'returns true (bans request)' do
            result = described_class.ip_should_be_banned?(test_ip)
            expect(result).to be true
          end
        end

        context 'when API returns Relay IP' do
          before do
            # Mock successful API response for Relay IP
            response_body = {
              'security' => {
                'vpn' => false,
                'proxy' => false,
                'tor' => false,
                'relay' => true
              }
            }
            
            allow(HTTParty).to receive(:get).and_return(
              double('response', 
                success?: true, 
                code: 200, 
                parsed_response: response_body
              )
            )
          end

          it 'returns true (bans request)' do
            result = described_class.ip_should_be_banned?(test_ip)
            expect(result).to be true
          end
        end

        context 'when API fails' do
          before do
            allow(HTTParty).to receive(:get).and_return(
              double('response', success?: false, code: 500)
            )
          end

          it 'returns false (fails open for availability)' do
            result = described_class.ip_should_be_banned?(test_ip)
            expect(result).to be false
          end

          it 'logs the error' do
            expect(Rails.logger).to receive(:warn).with(/VPNAPI returned non-success status/)
            described_class.ip_should_be_banned?(test_ip)
          end
        end

        context 'when API times out' do
          before do
            allow(HTTParty).to receive(:get).and_raise(Timeout::Error.new('timeout'))
          end

          it 'returns false (fails open for availability)' do
            result = described_class.ip_should_be_banned?(test_ip)
            expect(result).to be false
          end

          it 'logs the error' do
            expect(Rails.logger).to receive(:warn).with(/VPNAPI timeout\/error.*timeout/i)
            described_class.ip_should_be_banned?(test_ip)
          end
        end

        context 'when API returns invalid response' do
          before do
            # Mock response with missing security data
            allow(HTTParty).to receive(:get).and_return(
              double('response', 
                success?: true, 
                code: 200, 
                parsed_response: { 'invalid' => 'data' }
              )
            )
          end

          it 'returns false (treats as legitimate)' do
            result = described_class.ip_should_be_banned?(test_ip)
            expect(result).to be false
          end

          it 'caches the allowed result' do
            described_class.ip_should_be_banned?(test_ip)
            expect(VpnCacheService).to have_received(:set).with(test_ip, 'allowed')
          end
        end
      end
    end

    context 'with Redis connection issues' do
      before do
        allow(Rails.application.credentials).to receive(:vpnapi_key).and_return('test_api_key')
        # Mock cache service to simulate Redis errors
        allow(VpnCacheService).to receive(:get).with(test_ip).and_return(nil)
        allow(VpnCacheService).to receive(:set).and_raise(StandardError.new('Redis down'))
        
        # Mock a successful HTTP response so the test focuses on Redis error
        allow(HTTParty).to receive(:get).and_return(
          double('response', success?: true, code: 200, parsed_response: { 'security' => { 'vpn' => false, 'proxy' => false, 'tor' => false, 'relay' => false } })
        )
      end

      it 'returns false (fails open for availability)' do
        result = described_class.ip_should_be_banned?(test_ip)
        expect(result).to be false
      end

      it 'still processes the request despite cache errors' do
        result = described_class.ip_should_be_banned?(test_ip)
        
        expect(result).to be false
        expect(VpnCacheService).to have_received(:get).with(test_ip)
        expect(VpnCacheService).to have_received(:set).with(test_ip, 'allowed')
      end
    end
  end
end
