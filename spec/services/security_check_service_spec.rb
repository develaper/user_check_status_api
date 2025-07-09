require 'rails_helper'

RSpec.describe SecurityCheckService, type: :service do
  let(:user) { create(:user, ban_status: :not_banned) }
  let(:banned_user) { create(:user, ban_status: :banned) }
  let(:request_double) do
    double('request').tap do |req|
      allow(req).to receive(:headers).and_return({})
      allow(req).to receive(:remote_ip).and_return('192.168.1.1')
      allow(req).to receive(:ip).and_return('192.168.1.1')
    end
  end

  before do
    CountryWhitelistService.clear_whitelist
    CountryWhitelistService.add_countries('US', 'CA', 'GB', 'DE')
  end

  after do
    CountryWhitelistService.clear_whitelist
  end

  describe '.evaluate_user' do
    context 'when user is already banned' do
      it 'returns banned status' do
        result = described_class.evaluate_user(banned_user, {})
        expect(result).to eq('banned')
      end
    end

    context 'when user is not banned' do
      context 'with no request context' do
        it 'returns user ban status' do
          result = described_class.evaluate_user(user, {})
          expect(result).to eq('not_banned')
        end
      end

      context 'with CF-IPCountry header checks' do
        context 'when CF-IPCountry header is missing' do
          it 'allows the request (returns user status)' do
            allow(request_double).to receive(:headers).and_return({})
            request_context = { request: request_double }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end

        context 'when CF-IPCountry header contains whitelisted country' do
          it 'allows the request' do
            allow(request_double).to receive(:headers).and_return({ 'CF-IPCountry' => 'US' })
            request_context = { request: request_double }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end

        context 'when CF-IPCountry header contains non-whitelisted country' do
          it 'bans the user' do
            allow(request_double).to receive(:headers).and_return({ 'CF-IPCountry' => 'CN' })
            request_context = { request: request_double }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('banned')
          end
        end

        context 'when CF-IPCountry header is blank' do
          it 'allows the request' do
            allow(request_double).to receive(:headers).and_return({ 'CF-IPCountry' => '' })
            request_context = { request: request_double }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end

        context 'when CF-IPCountry header case variations' do
          it 'handles lowercase country codes' do
            allow(request_double).to receive(:headers).and_return({ 'CF-IPCountry' => 'us' })
            request_context = { request: request_double }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end
      end

      context 'with rooted device checks' do
        context 'when rooted_device is false' do
          it 'allows the request' do
            request_context = { rooted_device: false }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end

        context 'when rooted_device is true' do
          it 'bans the user' do
            request_context = { rooted_device: true }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('banned')
          end
        end

        context 'when rooted_device is nil' do
          it 'allows the request (treats as not rooted)' do
            request_context = { rooted_device: nil }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end

        context 'when rooted_device key is missing' do
          it 'allows the request (treats as not rooted)' do
            request_context = {}
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end
      end

      context 'with VPN detection checks' do
        before do
          # Mock IpAnalysisService to return a test IP
          allow(IpAnalysisService).to receive(:extract_ip_from_request).and_return('1.2.3.4')
        end

        context 'when IP is not from VPN/Tor/Proxy' do
          it 'allows the request' do
            allow(VpnDetectionService).to receive(:ip_should_be_banned?).with('1.2.3.4').and_return(false)
            request_context = { request: request_double }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end

        context 'when IP is from VPN/Tor/Proxy' do
          it 'bans the user' do
            allow(VpnDetectionService).to receive(:ip_should_be_banned?).with('1.2.3.4').and_return(true)
            request_context = { request: request_double }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('banned')
          end
        end

        context 'when no request object is provided' do
          it 'skips VPN check and allows the request' do
            request_context = {}
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end

        context 'when IP extraction fails' do
          it 'skips VPN check and allows the request' do
            allow(IpAnalysisService).to receive(:extract_ip_from_request).and_return(nil)
            request_context = { request: request_double }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end
      end

      context 'with multiple security checks' do
        before do
          allow(IpAnalysisService).to receive(:extract_ip_from_request).and_return('1.2.3.4')
        end

        context 'when country, rooted device, and VPN checks all fail' do
          it 'bans the user (country check fails first)' do
            allow(request_double).to receive(:headers).and_return({ 'CF-IPCountry' => 'CN' })
            allow(VpnDetectionService).to receive(:ip_should_be_banned?).and_return(true)
            request_context = { request: request_double, rooted_device: true }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('banned')
          end
        end

        context 'when VPN check fails but other checks pass' do
          it 'bans the user' do
            allow(request_double).to receive(:headers).and_return({ 'CF-IPCountry' => 'US' })
            allow(VpnDetectionService).to receive(:ip_should_be_banned?).with('1.2.3.4').and_return(true)
            request_context = { request: request_double, rooted_device: false }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('banned')
          end
        end

        context 'when country and rooted device checks fail but VPN check passes' do
          it 'bans the user (country check fails first)' do
            allow(request_double).to receive(:headers).and_return({ 'CF-IPCountry' => 'CN' })
            allow(VpnDetectionService).to receive(:ip_should_be_banned?).and_return(false)
            request_context = { request: request_double, rooted_device: true }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('banned')
          end
        end

        context 'when all checks pass' do
          it 'allows the request' do
            allow(request_double).to receive(:headers).and_return({ 'CF-IPCountry' => 'US' })
            allow(VpnDetectionService).to receive(:ip_should_be_banned?).with('1.2.3.4').and_return(false)
            request_context = { request: request_double, rooted_device: false }
            
            result = described_class.evaluate_user(user, request_context)
            expect(result).to eq('not_banned')
          end
        end
      end
    end
  end
end
