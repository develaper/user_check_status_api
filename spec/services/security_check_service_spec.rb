require 'rails_helper'

RSpec.describe SecurityCheckService, type: :service do
  let(:user) { create(:user, ban_status: :not_banned) }
  let(:banned_user) { create(:user, ban_status: :banned) }
  let(:request_double) { double('request') }

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
    end
  end
end