require 'rails_helper'

RSpec.describe IpAnalysisService, type: :service do
  describe '.extract_ip_from_request' do
    let(:request) { double('request') }

    context 'when request is nil' do
      it 'returns nil' do
        expect(IpAnalysisService.extract_ip_from_request(nil)).to be_nil
      end
    end

    context 'when request has HTTP_X_FORWARDED_FOR header' do
      before do
        allow(request).to receive(:headers).and_return({
          'HTTP_X_FORWARDED_FOR' => '192.168.1.100, 10.0.0.1'
        })
      end

      it 'returns the first IP from the forwarded header' do
        expect(IpAnalysisService.extract_ip_from_request(request)).to eq('192.168.1.100')
      end
    end

    context 'when request has HTTP_X_REAL_IP header' do
      before do
        allow(request).to receive(:headers).and_return({
          'HTTP_X_REAL_IP' => '192.168.1.200'
        })
      end

      it 'returns the real IP' do
        expect(IpAnalysisService.extract_ip_from_request(request)).to eq('192.168.1.200')
      end
    end

    context 'when request has remote_ip' do
      before do
        allow(request).to receive(:headers).and_return({})
        allow(request).to receive(:remote_ip).and_return('192.168.1.300')
      end

      it 'returns the remote IP' do
        expect(IpAnalysisService.extract_ip_from_request(request)).to eq('192.168.1.300')
      end
    end

    context 'when request has only ip' do
      before do
        allow(request).to receive(:headers).and_return({})
        allow(request).to receive(:remote_ip).and_return(nil)
        allow(request).to receive(:ip).and_return('192.168.1.400')
      end

      it 'returns the IP' do
        expect(IpAnalysisService.extract_ip_from_request(request)).to eq('192.168.1.400')
      end
    end
  end

  describe '.detect_country_from_ip' do
    context 'when IP is nil' do
      it 'returns Unknown' do
        expect(IpAnalysisService.detect_country_from_ip(nil)).to eq('Unknown')
      end
    end

    context 'when IP is provided' do
      it 'returns Unknown as placeholder' do
        result = IpAnalysisService.detect_country_from_ip('192.168.1.100')
        expect(result).to eq('Unknown') # This will change when real geolocation is implemented
      end
    end
  end
end