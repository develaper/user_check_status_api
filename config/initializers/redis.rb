# Redis configuration
$redis = if Rails.env.test?
  require 'mock_redis'
  MockRedis.new
else
  Redis.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    timeout: 1,
    reconnect_attempts: 3
  )
end

# Test Redis connection (only for non-test environments)
unless Rails.env.test?
  begin
    $redis.ping
    Rails.logger.info "Redis connection established successfully"
  rescue Redis::CannotConnectError => e
    Rails.logger.warn "Redis connection failed: #{e.message}. Some features may not work properly."
  end
end