class Api::V1::BaseController < ApplicationController
  # Skip CSRF protection for API requests
  skip_before_action :verify_authenticity_token
  
  # Set JSON response format
  before_action :set_default_response_format
  
  protected
  
  def set_default_response_format
    request.format = :json
  end
  
  # Standard error responses
  def render_success(data = {}, message = "Success")
    render json: {
      success: true,
      message: message,
      data: data
    }, status: :ok
  end
  
  def render_error(message = "Error", status = :unprocessable_entity)
    render json: {
      success: false,
      message: message
    }, status: status
  end
  
  def render_not_found(message = "Resource not found")
    render json: {
      success: false,
      message: message
    }, status: :not_found
  end
end