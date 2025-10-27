class ErrorsController < ApplicationController
  skip_before_action :current_user
  
  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: "Not found" }, status: :not_found }
      format.all { render status: :not_found, body: nil }
    end
  end
  
  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
      format.all { render status: :internal_server_error, body: nil }
    end
  end
end
