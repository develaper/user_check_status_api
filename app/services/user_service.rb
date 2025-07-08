class UserService
  def self.create_user(user_params, request_context = {})
    user = User.new(user_params)
    
    if user.save
      log_integrity_event(user, 'user_creation', {}, request_context)
      Result.success(user)
    else
      Result.failure(user.errors)
    end
  rescue => e
    Rails.logger.error "Failed to create user: #{e.message}"
    Result.failure([e.message])
  end
  
  def self.update_ban_status(user, new_ban_status, request_context = {})
    return Result.failure(["User is required"]) unless user
    return Result.failure(["Invalid ban status"]) unless User.ban_statuses.key?(new_ban_status.to_s)
    
    old_ban_status = user.ban_status
    user.ban_status = new_ban_status
    
    if user.save
      log_integrity_event(user, 'ban_status_change', {
        old_ban_status: old_ban_status,
        new_ban_status: new_ban_status
      }, request_context)
      Result.success(user)
    else
      Result.failure(user.errors)
    end
  rescue => e
    Rails.logger.error "Failed to update ban status: #{e.message}"
    Result.failure([e.message])
  end

  private

  def self.log_integrity_event(user, event_type, event_data, request_context)
    IntegrityLogService.log_event(user, event_type, event_data, request_context)
  rescue => e
    Rails.logger.error "Failed to log #{event_type}: #{e.message}"
    # Continue execution - logging failure shouldn't break the core operation
  end
end