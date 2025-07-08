module BanStatusEnum
  extend ActiveSupport::Concern
  
  included do
    # Define the enum values in one place so we can reuse them in integrity logs and user models
    # This allows us to maintain consistency and avoid duplication
    # across different models that need to use the same ban status values.
    # Ready to add more values like: suspended: 2, under_review: 3
    enum ban_status: {
      not_banned: 0,
      banned: 1
    }
  end
  
  # Class methods for accessing enum values so we can write User.ban_status_values
  # and IntegrityLog.ban_status_values without duplicating logic in each model.
  # This keeps our code DRY and allows us to easily add new ban statuses in the future.
  class_methods do
    def ban_status_values
      ban_statuses
    end
    
    def ban_status_options
      ban_statuses.map { |key, value| [key.humanize, key] }
    end
  end
end