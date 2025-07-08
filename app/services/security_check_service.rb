class SecurityCheckService
  class << self
    def evaluate_user(user, request_context = {})
      Rails.logger.info "Running security checks for user #{user.idfa}"
      
      return 'banned' if user.ban_status == 'banned'
      
      return 'banned' if country_check_failed?(request_context)

      return 'banned' if rooted_device_check_failed?(request_context)
      
      user.ban_status
    end
    
    private
    
    def country_check_failed?(request_context)
      request = request_context[:request]
      return false unless request
      
      cf_country = request.headers['CF-IPCountry']
      Rails.logger.info "CF-IPCountry header: #{cf_country || 'missing'}"
      
      # If CF-IPCountry header is missing, this might be suspicious
      # but we'll allow it for now (could be a direct access or a cloudflare issue)
      return false if cf_country.blank?
      
      unless CountryWhitelistService.country_whitelisted?(cf_country)
        Rails.logger.warn "Country check failed: #{cf_country} is not whitelisted"
        return true
      end
      
      Rails.logger.info "Country check passed: #{cf_country} is whitelisted"
      false
    end
    
    # Controller ensures only boolean values reach this method
    def rooted_device_check_failed?(request_context)
      rooted_device = request_context[:rooted_device]
      
      Rails.logger.info "Rooted device check: #{rooted_device.inspect}"
      
      if rooted_device == true
        Rails.logger.warn "Rooted device check failed: device is rooted"
        return true
      end
      
      Rails.logger.info "Rooted device check passed: device is not rooted"
      false
    end
  end
end