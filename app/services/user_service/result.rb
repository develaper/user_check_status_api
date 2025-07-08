# Result object for UserService operations
class UserService::Result
  attr_reader :data, :errors, :success

  def initialize(success:, data: nil, errors: nil)
    @success = success
    @data = data
    @errors = errors
  end

  def self.success(data)
    new(success: true, data: data)
  end

  def self.failure(errors)
    new(success: false, errors: errors)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end