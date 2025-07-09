class VpnCacheService
  # Cache duration: 24 hours
  CACHE_DURATION = 24.hours.to_i
  
  class << self
    def get(ip)
      return nil if ip.blank?
      
      cache_key = build_cache_key(ip)
      result = Redis.current.get(cache_key)
      
      if result
        Rails.logger.info "VPN cache hit for IP #{ip}: #{result}"
      else
        Rails.logger.info "VPN cache miss for IP #{ip}"
      end
      
      result
    rescue => e
      Rails.logger.error "Redis get failed for VPN check (IP: #{ip}): #{e.message}"
      nil
    end
    
    def set(ip, result)
      return if ip.blank? || result.blank?
      
      cache_key = build_cache_key(ip)
      Redis.current.setex(cache_key, CACHE_DURATION, result)
      Rails.logger.info "Cached VPN result for IP #{ip}: #{result} (expires in #{CACHE_DURATION}s)"
    rescue => e
      Rails.logger.error "Redis setex failed for VPN check (IP: #{ip}): #{e.message}"
    end
    
    def delete(ip)
      return if ip.blank?
      
      cache_key = build_cache_key(ip)
      Redis.current.del(cache_key)
      Rails.logger.info "Deleted VPN cache for IP #{ip}"
    rescue => e
      Rails.logger.error "Redis delete failed for VPN check (IP: #{ip}): #{e.message}"
    end
    
    private
    
    def build_cache_key(ip)
      "vpn_check:#{ip}"
    end
  end
end
