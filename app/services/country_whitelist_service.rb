class CountryWhitelistService
  REDIS_KEY = 'country_whitelist'
  
  # Default countries for whitelist (common safe countries)
  DEFAULT_COUNTRIES = %w[
    US CA GB DE FR AU NL SE NO DK FI
    CH AT BE IE NZ SG JP KR
  ].freeze
  
  class << self
    def add_countries(*countries)
      $redis.sadd(REDIS_KEY, countries.map(&:upcase))
    end
    
    def remove_countries(*countries)
      $redis.srem(REDIS_KEY, countries.map(&:upcase))
    end
    
    def country_whitelisted?(country)
      return false if country.blank?
      $redis.sismember(REDIS_KEY, country.upcase)
    end
    
    def whitelisted_countries
      $redis.smembers(REDIS_KEY)
    end
    
    def clear_whitelist
      $redis.del(REDIS_KEY)
    end
    
    def initialize_default_whitelist
      add_countries(*DEFAULT_COUNTRIES)
      Rails.logger.info "Initialized country whitelist with #{DEFAULT_COUNTRIES.size} countries"
    end
    
    def whitelist_size
      $redis.scard(REDIS_KEY)
    end
  end
end