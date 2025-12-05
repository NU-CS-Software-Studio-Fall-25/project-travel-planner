class RecommendationFeedbacksController < ApplicationController
  before_action :require_login
  before_action :verify_json_request, only: [:create, :destroy, :remove]

  def create
    # Input validation and sanitization
    feedback_params_sanitized = sanitize_feedback_params(feedback_params)
    
    # Validate required fields are present after sanitization
    if feedback_params_sanitized[:destination_city].blank? || feedback_params_sanitized[:destination_country].blank?
      render json: { 
        success: false, 
        errors: ["Destination city and country are required"] 
      }, status: :unprocessable_entity
      return
    end
    
    # Check if feedback already exists for this destination
    existing_feedback = current_user.recommendation_feedbacks.find_by(
      destination_city: feedback_params_sanitized[:destination_city],
      destination_country: feedback_params_sanitized[:destination_country]
    )

    if existing_feedback
      # Update existing feedback
      if existing_feedback.update(feedback_params_sanitized)
        message = existing_feedback.feedback_type == 'like' ? 
                  'Successfully marked this recommendation as liked' : 
                  'Successfully marked this recommendation as disliked'
        render json: { 
          success: true, 
          message: message,
          feedback_type: existing_feedback.feedback_type 
        }
      else
        render json: { 
          success: false, 
          errors: existing_feedback.errors.full_messages 
        }, status: :unprocessable_entity
      end
    else
      # Create new feedback
      @feedback = current_user.recommendation_feedbacks.build(feedback_params_sanitized)
      
      if @feedback.save
        message = @feedback.feedback_type == 'like' ? 
                  'Successfully marked this recommendation as liked' : 
                  'Successfully marked this recommendation as disliked'
        render json: { 
          success: true, 
          message: message,
          feedback_type: @feedback.feedback_type 
        }
      else
        render json: { 
          success: false, 
          errors: @feedback.errors.full_messages 
        }, status: :unprocessable_entity
      end
    end
  end

  def destroy
    # Sanitize ID parameter to prevent SQL injection
    feedback_id = params[:id].to_i
    
    # Validate that feedback_id is positive
    if feedback_id <= 0
      render json: { success: false, message: "Invalid feedback ID" }, status: :bad_request
      return
    end
    
    @feedback = current_user.recommendation_feedbacks.find_by(id: feedback_id)
    
    if @feedback.nil?
      render json: { success: false, message: "Feedback not found" }, status: :not_found
      return
    end

    feedback_type = @feedback.feedback_type
    if @feedback.destroy
      message = feedback_type == 'like' ? 
                'Your like has been successfully removed' : 
                'Your dislike has been successfully removed'
      render json: { success: true, message: message }
    else
      render json: { success: false, errors: @feedback.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def remove
    # Remove feedback by destination (called when toggling off)
    city = params[:destination_city]&.strip&.slice(0, 100)
    country = params[:destination_country]&.strip&.slice(0, 100)
    feedback_type = params[:feedback_type]&.strip&.downcase
    
    if city.blank? || country.blank?
      render json: { success: false, message: "Destination required" }, status: :bad_request
      return
    end
    
    @feedback = current_user.recommendation_feedbacks.find_by(
      destination_city: city,
      destination_country: country,
      feedback_type: feedback_type
    )
    
    if @feedback.nil?
      render json: { success: false, message: "Feedback not found" }, status: :not_found
      return
    end

    feedback_type = @feedback.feedback_type
    if @feedback.destroy
      message = feedback_type == 'like' ? 
                'Your like has been successfully removed' : 
                'Your dislike has been successfully removed'
      render json: { success: true, message: message }
    else
      render json: { success: false, errors: @feedback.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    @feedbacks = current_user.recommendation_feedbacks.recent.limit(50)
    
    # Group feedbacks by type for easy display
    @liked = @feedbacks.likes
    @disliked = @feedbacks.dislikes
  end

  private

  def verify_json_request
    unless request.format.json? || request.content_type&.include?('application/json')
      render json: { success: false, message: "Invalid content type" }, status: :not_acceptable
    end
  end

  def require_login
    unless logged_in?
      if request.format.json?
        render json: { success: false, message: "Please log in to continue" }, status: :unauthorized
      else
        redirect_to login_path, alert: "Please log in to continue"
      end
    end
  end

  def feedback_params
    params.require(:recommendation_feedback).permit(
      :destination_city,
      :destination_country,
      :trip_type,
      :travel_style,
      :budget_min,
      :budget_max,
      :length_of_stay,
      :feedback_type,
      :reason
    )
  end

  def sanitize_feedback_params(params)
    # Strip whitespace and enforce length limits for security
    {
      destination_city: params[:destination_city]&.strip&.slice(0, 100),
      destination_country: params[:destination_country]&.strip&.slice(0, 100),
      trip_type: params[:trip_type]&.strip&.slice(0, 50),
      travel_style: params[:travel_style]&.strip&.slice(0, 50),
      budget_min: params[:budget_min]&.to_i&.abs || 0,
      budget_max: params[:budget_max]&.to_i&.abs || 0,
      length_of_stay: params[:length_of_stay]&.to_i&.abs || 0,
      feedback_type: params[:feedback_type]&.strip&.downcase,
      reason: params[:reason]&.strip&.slice(0, 500)
    }.compact
  end
end
