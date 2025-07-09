require 'httparty'

class VpnDetectionService
  include HTTParty
  
  base_uri 'https://vpnapi.io'
  
  class << self
    def ip_should_be_banned?(ip)
      return false if ip.blank?
      
      Rails.logger.info "VPN detection check for IP: #{ip}"
      
      cached_result = VpnCacheService.get(ip)
      if cached_result
        return cached_result == 'banned'
      end
      
      api_result = check_ip_with_vpnapi(ip)
      
      # Cache the result
      VpnCacheService.set(ip, api_result)
      
      api_result == 'banned'
    rescue => e
      # If any error occurs, log it and allow the request (fail open for availability)
      Rails.logger.error "VPN detection failed for IP #{ip}: #{e.message}"
      false
    end
    
    private
    
    def check_ip_with_vpnapi(ip)
      api_key = vpnapi_key
      return 'allowed' unless api_key
      
      Rails.logger.info "Making VPNAPI call for IP: #{ip}"
      
      response = make_vpnapi_request(ip, api_key)
      result = handle_vpnapi_response(response, ip)
      
      Rails.logger.info "VPNAPI response for #{ip}: #{result}"
      result
    rescue Timeout::Error, HTTParty::Error => e
      Rails.logger.warn "VPNAPI timeout/error for IP #{ip}: #{e.message}"
      'allowed' # Fail open on timeout
    end
    
    def make_vpnapi_request(ip, api_key)
      HTTParty.get(
        "/api/#{ip}",
        query: { key: api_key },
        timeout: 5,
        headers: {
          'User-Agent' => 'Rails-Security-Check/1.0'
        }
      )
    end
    
    def handle_vpnapi_response(response, ip)
      if response.success?
        parse_vpnapi_response(response.parsed_response, ip)
      else
        Rails.logger.warn "VPNAPI returned non-success status #{response.code} for IP #{ip}"
        'allowed' # Fail open
      end
    end
    
    def parse_vpnapi_response(data, ip)
      # VPNAPI response structure:
      # {
      #   "security": {
      #     "vpn": true/false,
      #     "proxy": true/false,
      #     "tor": true/false,
      #     "relay": true/false
      #   }
      # }
      
      return 'allowed' unless data.is_a?(Hash)
      
      security = data['security']
      return 'allowed' unless security.is_a?(Hash)
      
      is_vpn = security['vpn']
      is_proxy = security['proxy'] 
      is_tor = security['tor']
      is_relay = security['relay']
      
      if is_vpn || is_proxy || is_tor || is_relay
        Rails.logger.warn "IP #{ip} detected as suspicious: VPN=#{is_vpn}, Proxy=#{is_proxy}, Tor=#{is_tor}, Relay=#{is_relay}"
        'banned'
      else
        'allowed'
      end
    end
    
    def vpnapi_key
      ENV['VPNAPI_KEY'] || Rails.application.credentials.vpnapi_key
    end
  end
end
