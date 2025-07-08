class V1::UsersController < ApplicationController
  # Custom error for invalid rooted_device parameter
  class InvalidRootedDeviceError < ActionController::BadRequest
    MESSAGE = "rooted_device parameter must be a boolean (true or false)".freeze
    
    def initialize(msg = MESSAGE)
      super(msg)
    end
  end

  # POST /v1/user/check_status
  def check_status
    request_context = build_request_context
    idfa = params.require(:idfa)
    
    user = find_or_create_user(idfa, request_context)
    return if performed? # Early return if user creation failed
    
    ban_status = determine_ban_status(user, request_context)
    
    render json: { ban_status: ban_status }
  rescue ActionController::ParameterMissing => e
    render json: { errors: ["Missing required parameter: #{e.param}"] }, status: :bad_request
  rescue InvalidRootedDeviceError => e
    render json: { errors: [e.message] }, status: :bad_request
  rescue ActionController::BadRequest => e
    render json: { errors: [e.message] }, status: :bad_request
  rescue => e
    Rails.logger.error "Error in check_status: #{e.message}"
    render json: { errors: ["Internal server error"] }, status: :internal_server_error
  end

  private

  def find_or_create_user(idfa, request_context)
    user = User.find_by(idfa: idfa)
    return user if user

    result = UserService.create_user(
      { idfa: idfa, ban_status: :not_banned }, 
      request_context
    )
    
    unless result.success?
      render json: { errors: result.errors }, status: :unprocessable_entity
      return
    end
  
    result.data
  end

  def determine_ban_status(user, request_context)
    ban_status = SecurityCheckService.evaluate_user(user, request_context)
    update_user_if_banned(user, ban_status, request_context)
    
    ban_status
  end

  def update_user_if_banned(user, ban_status, request_context)
    return unless ban_status == 'banned' && user.ban_status != 'banned'

    UserService.update_ban_status(user, :banned, request_context)
  end

  def build_request_context
    {
      ip: IpAnalysisService.extract_ip_from_request(request),
      rooted_device: validate_rooted_device_param,
      request: request, # Needed for IP extraction fallback in IntegrityLogService
      timestamp: Time.current
    }
  end

  def validate_rooted_device_param
    rooted_device = params[:rooted_device]
    
    # Missing parameter defaults to false (not rooted)
    return false if rooted_device.nil?
    
    # Only accept actual boolean values (JSON API)
    unless rooted_device.is_a?(TrueClass) || rooted_device.is_a?(FalseClass)
      raise InvalidRootedDeviceError
    end
    
    rooted_device
  end
end