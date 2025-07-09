# Redis configuration
if Rails.env.test?
  require 'mock_redis'
  # For tests, mocking will be handled in test files
  # Set up a placeholder - tests will override this
  $redis = MockRedis.new
elsif Rails.env.development?
  # In development, we might not have Redis running
  # Set up a connection but don't fail if it's not available
  begin
    redis_connection = Redis.new(
      url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
      timeout: 1,
      reconnect_attempts: 1
    )
    redis_connection.ping # Test connection
    $redis = redis_connection
    Rails.logger.info "Redis connection established successfully"
  rescue => e
    Rails.logger.warn "Redis connection failed: #{e.message}. Using MockRedis for development."
    require 'mock_redis'
    $redis = MockRedis.new
  end
else
  # Production Redis setup
  redis_connection = Redis.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    timeout: 1,
    reconnect_attempts: 3
  )
  $redis = redis_connection
  
  begin
    $redis.ping
    Rails.logger.info "Redis connection established successfully"
  rescue => e
    Rails.logger.error "Redis connection failed in production: #{e.message}"
    raise e # Fail fast in production
  end
end

# Set up Redis.current for VPN detection service compatibility
if defined?(Redis)
  # Monkey patch to make Redis.current work consistently
  class << Redis
    def current
      $redis
    end
  end
end
