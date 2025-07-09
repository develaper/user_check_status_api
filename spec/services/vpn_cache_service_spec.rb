require 'rails_helper'

RSpec.describe VpnCacheService, type: :service do
  let(:ip) { '1.2.3.4' }
  let(:cache_key) { 'vpn_check:1.2.3.4' }
  let(:cache_duration) { 24.hours.to_i }

  before do
    allow(Redis.current).to receive(:get)
    allow(Redis.current).to receive(:setex)
    allow(Redis.current).to receive(:del)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '.get' do
    context 'when cache hit' do
      it 'returns cached result and logs cache hit' do
        allow(Redis.current).to receive(:get).with(cache_key).and_return('banned')

        result = VpnCacheService.get(ip)

        expect(result).to eq('banned')
        expect(Rails.logger).to have_received(:info).with("VPN cache hit for IP #{ip}: banned")
      end
    end

    context 'when cache miss' do
      it 'returns nil and logs cache miss' do
        allow(Redis.current).to receive(:get).with(cache_key).and_return(nil)

        result = VpnCacheService.get(ip)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:info).with("VPN cache miss for IP #{ip}")
      end
    end

    context 'when Redis fails' do
      it 'returns nil and logs error' do
        redis_error = StandardError.new('Redis connection failed')
        allow(Redis.current).to receive(:get).with(cache_key).and_raise(redis_error)

        result = VpnCacheService.get(ip)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with("Redis get failed for VPN check (IP: #{ip}): Redis connection failed")
      end
    end

    context 'with blank IP' do
      it 'returns nil without calling Redis' do
        result = VpnCacheService.get('')

        expect(result).to be_nil
        expect(Redis.current).not_to have_received(:get)
      end
    end
  end

  describe '.set' do
    it 'caches result with correct expiration and logs success' do
      VpnCacheService.set(ip, 'allowed')

      expect(Redis.current).to have_received(:setex).with(cache_key, cache_duration, 'allowed')
      expect(Rails.logger).to have_received(:info).with("Cached VPN result for IP #{ip}: allowed (expires in #{cache_duration}s)")
    end

    context 'when Redis fails' do
      it 'logs error' do
        redis_error = StandardError.new('Redis connection failed')
        allow(Redis.current).to receive(:setex).and_raise(redis_error)

        VpnCacheService.set(ip, 'banned')

        expect(Rails.logger).to have_received(:error).with("Redis setex failed for VPN check (IP: #{ip}): Redis connection failed")
      end
    end

    context 'with blank IP' do
      it 'does not call Redis' do
        VpnCacheService.set('', 'allowed')

        expect(Redis.current).not_to have_received(:setex)
      end
    end

    context 'with blank result' do
      it 'does not call Redis' do
        VpnCacheService.set(ip, '')

        expect(Redis.current).not_to have_received(:setex)
      end
    end
  end

  describe '.delete' do
    it 'deletes cache entry and logs success' do
      VpnCacheService.delete(ip)

      expect(Redis.current).to have_received(:del).with(cache_key)
      expect(Rails.logger).to have_received(:info).with("Deleted VPN cache for IP #{ip}")
    end

    context 'when Redis fails' do
      it 'logs error' do
        redis_error = StandardError.new('Redis connection failed')
        allow(Redis.current).to receive(:del).and_raise(redis_error)

        VpnCacheService.delete(ip)

        expect(Rails.logger).to have_received(:error).with("Redis delete failed for VPN check (IP: #{ip}): Redis connection failed")
      end
    end

    context 'with blank IP' do
      it 'does not call Redis' do
        VpnCacheService.delete('')

        expect(Redis.current).not_to have_received(:del)
      end
    end
  end
end
