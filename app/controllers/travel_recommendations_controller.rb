# app/controllers/travel_recommendations_controller.rb
class TravelRecommendationsController < ApplicationController
  before_action :require_login

  def index
    # Load last recommendations from the current user's database record
    # Convert string keys to symbol keys for view compatibility
    stored_recommendations = current_user.recommendations_json || []
    # Convert to symbolized keys for view compatibility (you already do that)
    recs = stored_recommendations.map { |rec| rec.deep_symbolize_keys }

    @pagy, @recommendations = pagy_array(recs, items: 5)

    # Load all countries from the database for the dropdown
    @countries = CountrySafetyScore.where(year: 2025).order(:country_name).pluck(:country_name).uniq
    
    # Load last preferences from session to pre-fill the form
    last_prefs = session[:last_preferences] || {}
    @travel_plan = TravelPlan.new(last_prefs)

    @max_trip_days = (current_user&.subscription_tier == 'premium') ? 14 : 7
    
    # If we have recommendations, show a helpful message
    if @recommendations.present?
      if last_prefs.present?
        flash.now[:info] = "Showing your recent recommendations. You can save multiple plans or generate new ones below!"
      else
        flash.now[:info] = "Welcome back! These are your last generated recommendations. Fill out the form below to get new ones!"
      end
    end
  end

  def create
    preferences = travel_plan_params
    
    # Calculate length of stay from dates
    if preferences[:start_date].present? && preferences[:end_date].present?
      start_date = Date.parse(preferences[:start_date]) rescue nil
      end_date = Date.parse(preferences[:end_date]) rescue nil
      
      if start_date && end_date && end_date >= start_date
        preferences[:length_of_stay] = (end_date - start_date).to_i + 1
        # Derive the travel month from start_date
        preferences[:travel_month] = start_date.strftime("%B") # e.g., "November"
      end
    end
    
    # Store preferences in session for form pre-filling, but exclude safety_levels (not a TravelPlan attribute)
    session_prefs = preferences.to_h.except(:safety_levels)
    session[:last_preferences] = session_prefs

    @recommendations = OpenaiService.new(preferences).get_recommendations
    # Store the new recommendations in the user's database record instead of session
    current_user.update(recommendations_json: @recommendations)
    
    # Create TravelPlan object for form display (without safety_levels attribute)
    @travel_plan = TravelPlan.new(session_prefs)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "recommendations_list",
          partial: "travel_recommendations/recommendations_list",
          locals: { recommendations: @recommendations }
        )
      end
      format.html { redirect_to travel_recommendations_path, notice: "Recommendations generated." }
    end
  end

  def destroy
    # Remove the recommendation from the user's stored recommendations by its index
    index_to_delete = params[:id].to_i
    recommendations = current_user.recommendations_json || []
    if recommendations[index_to_delete]
      recommendations.delete_at(index_to_delete)
      current_user.update(recommendations_json: recommendations)
    end

    # Respond to the Turbo Stream request by removing the element from the page
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("recommendation-#{params[:id]}") }
      format.html { redirect_to travel_recommendations_path, notice: "Recommendation deleted." }
    end
  end

  # New action to fetch TripAdvisor photos for a destination
  def fetch_photos
    destination_city = params[:destination_city]
    destination_country = params[:destination_country]
    
    Rails.logger.info "="*80
    Rails.logger.info "FETCH_PHOTOS Controller - Received Parameters:"
    Rails.logger.info "destination_city param: '#{destination_city}'"
    Rails.logger.info "destination_country param: '#{destination_country}'"
    Rails.logger.info "All params: #{params.inspect}"
    Rails.logger.info "="*80
    
    unless destination_city.present? && destination_country.present?
      Rails.logger.error "Missing destination information!"
      render json: { success: false, error: 'Missing destination information' }, status: :bad_request
      return
    end

    tripadvisor_service = TripadvisorService.new
    result = tripadvisor_service.get_location_photos(destination_city, destination_country, 7)
    
    Rails.logger.info "Result success: #{result[:success]}"
    Rails.logger.info "Result photos count: #{result[:photos]&.length || 0}"
    
    render json: result
  end

  private

  def travel_plan_params
    params.require(:travel_plan).permit(
      :name, :passport_country, :current_location, :budget_min, :budget_max,
      :length_of_stay, :travel_style, :travel_month, :trip_scope, :number_of_travelers,
      :general_purpose, :start_date, :end_date, :safety_preference
    )
  end

  def require_login
    unless logged_in?
      flash[:alert] = "You must be logged in to access this section."
      redirect_to login_path
    end
  end
end
