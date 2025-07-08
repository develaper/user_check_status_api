# Configuration for IntegrityLogService
Rails.application.config.after_initialize do
  case Rails.env
  when 'development'
    IntegrityLogService.configure_data_sources(:database)
  when 'test'
    IntegrityLogService.configure_data_sources(:database)
  when 'production'
    IntegrityLogService.configure_data_sources(:database)
  end
end