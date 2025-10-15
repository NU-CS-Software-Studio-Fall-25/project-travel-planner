# app/controllers/travel_recommendations_controller.rb
class TravelRecommendationsController < ApplicationController
  before_action :require_login

  def index
    # Load last preferences from user's recommendations_json or from a smaller session variable
    last_prefs = session[:last_preferences] || {}
    @travel_plan = TravelPlan.new(last_prefs)
    # Load recommendations from the current user's database record
    @recommendations = current_user.recommendations_json || []
  end

  def create
    preferences = travel_plan_params
    session[:last_preferences] = preferences.to_h

    @recommendations = OpenaiService.new(preferences).get_recommendations
    # Store the new recommendations in the user's database record instead of session
    current_user.update(recommendations_json: @recommendations)
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
