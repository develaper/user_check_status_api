class IntegrityLogService
  class << self
    attr_accessor :log_data_sources
  end

  def self.log_event(user, event_type, event_data = {}, request_data = {})
    enhanced_request_data = request_data.merge(
      additional_info: {
        event_type: event_type,
        event_data: event_data,
        logged_at: Time.current
      }
    )
    
    create_log_for_user(user, enhanced_request_data)
  end

  def self.create_log_for_user(user, request_data = {})
    log_data = build_log_data(user, request_data)
    
    log_data_sources&.each do |data_source|
      send_to_data_source(data_source, log_data)
    end
    
    # Return the database record if it was created
    log_data[:database_record] if log_data_sources&.include?(:database)
  end
  
  # Configuration method (used by initializer)
  def self.configure_data_sources(*data_sources)
    self.log_data_sources = data_sources
  end
  
  def self.add_data_source(data_source)
    self.log_data_sources ||= []
    self.log_data_sources << data_source unless log_data_sources.include?(data_source)
  end
  
  def self.remove_data_source(data_source)
    self.log_data_sources&.delete(data_source)
  end

  private

  def self.build_log_data(user, request_data)
    {
      idfa: user.idfa,
      ban_status: user.ban_status,
      ip: request_data[:ip] || IpAnalysisService.extract_ip_from_request(request_data[:request]) || 'Unknown',
      rooted_device: request_data[:rooted_device] || false,
      country: request_data[:country] || IpAnalysisService.detect_country_from_ip(request_data[:ip]) || 'Unknown',
      proxy: request_data[:proxy] || false,
      vpn: request_data[:vpn] || false,
      additional_info: request_data[:additional_info] || {},
      timestamp: Time.current
    }
  end
  
  def self.send_to_data_source(data_source, log_data)
    case data_source
    when :database
      log_data[:database_record] = write_to_database(log_data)
    else
      Rails.logger.warn "Unknown log data source: #{data_source}"
    end
  rescue => e
    Rails.logger.error "Failed to write to #{data_source}: #{e.message}"
    # Continue with other data sources even if one fails
  end
  
  def self.write_to_database(log_data)
    IntegrityLog.create!(log_data.except(:timestamp, :database_record))
  end
end