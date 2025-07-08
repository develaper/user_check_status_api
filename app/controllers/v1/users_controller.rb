class V1::UsersController < ApplicationController
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
      rooted_device: params[:rooted_device] || false,
      request: request, # Needed for IP extraction fallback in IntegrityLogService
      timestamp: Time.current
    }
  end
end