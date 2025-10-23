# app/controllers/travel_recommendations_controller.rb
class TravelRecommendationsController < ApplicationController
  before_action :require_login

  def index
    @travel_plan = TravelPlan.new(session.fetch(:last_preferences, {}))
    # Load recommendations from the user record, or initialize as an empty array
    @recommendations = current_user.cached_recommendations
  end

  def create
    preferences = travel_plan_params
    session[:last_preferences] = preferences.to_h

    @recommendations = OpenaiService.new(preferences).get_recommendations
    # Store the new recommendations in the user record instead of session
    current_user.cache_recommendations(@recommendations)
    @travel_plan = TravelPlan.new(preferences)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "recommendations_list",
          partial: "travel_recommendations/recommendations_list",
          locals: { recommendations: @recommendations }
        )
      end
      format.html { render :index }
    end
  end

  def destroy
    # Remove the recommendation from the user record by its index
    index_to_delete = params[:id].to_i
    recommendations = current_user.cached_recommendations
    
    if recommendations[index_to_delete]
      recommendations.delete_at(index_to_delete)
      current_user.cache_recommendations(recommendations)
    end

    # Respond to the Turbo Stream request by removing the element from the page
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("recommendation-#{params[:id]}") }
      format.html { redirect_to travel_recommendations_path, notice: "Recommendation deleted." }
    end
  end

  private

  def travel_plan_params
    params.require(:travel_plan).permit(
      :name, :passport_country, :budget_min, :budget_max, :safety_preference,
      :length_of_stay, :travel_style, :travel_month, :trip_scope, :trip_type,
      :general_purpose
    )
  end

  def require_login
    unless logged_in?
      flash[:alert] = "You must be logged in to access this section."
      redirect_to login_path
    end
  end
end
