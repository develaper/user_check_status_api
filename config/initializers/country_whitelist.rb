# Initialize country whitelist if it doesn't exist
Rails.application.config.after_initialize do
  begin
    # Only initialize if whitelist is empty
    if CountryWhitelistService.whitelist_size == 0
      CountryWhitelistService.initialize_default_whitelist
    else
      Rails.logger.info "Country whitelist already initialized with #{CountryWhitelistService.whitelist_size} countries"
    end
  rescue Redis::CannotConnectError => e
    Rails.logger.warn "Could not initialize country whitelist due to Redis connection issue: #{e.message}"
  end
end