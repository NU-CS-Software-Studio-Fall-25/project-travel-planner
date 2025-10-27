# app/controllers/travel_plans_controller.rb
class TravelPlansController < ApplicationController
  before_action :set_travel_plan, only: %i[ show edit update destroy ]
  before_action :require_login

  # GET /travel_plans or /travel_plans.json
  def index
    @travel_plans = current_user.travel_plans
  end

  # GET /travel_plans/1 or /travel_plans/1.json
  def show
  end

  # GET /travel_plans/new
  def new
    @travel_plan = TravelPlan.new
  end

  # GET /travel_plans/1/edit
  def edit
  end

  # POST /travel_plans or /travel_plans.json
  def create
    # Check if travel_plan params exist
    unless params[:travel_plan].present?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("notifications", 
                                                     partial: "shared/error_notification",
                                                     locals: { message: "Invalid request: missing travel plan data" })
        end
        format.html { redirect_to travel_recommendations_path, alert: "Invalid request: missing travel plan data" }
        format.json { render json: { error: "Missing travel plan data" }, status: :unprocessable_entity }
      end
      return
    end
    
    # Find or create destination based on recommendation data
    destination = find_or_create_destination_from_params
    
    # Build travel plan with the destination
    plan_params = travel_plan_params
    
    # Convert safety_level to safety_score if present
    if plan_params[:safety_level].present?
      plan_params[:safety_score] = case plan_params[:safety_level]
      when "level_1" then 9
      when "level_2" then 7
      when "level_3" then 4
      when "level_4" then 2
      else 5
      end
      plan_params.delete(:safety_level)
    end
    
    @travel_plan = current_user.travel_plans.build(plan_params)
    @travel_plan.destination = destination if destination
    
    # Set default dates if not provided
    set_default_dates if @travel_plan.start_date.nil? || @travel_plan.end_date.nil?

    respond_to do |format|
      if @travel_plan.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("notifications", partial: "shared/success_notification", 
                                 locals: { message: "Travel plan saved successfully!", 
                                          travel_plan: @travel_plan })
          ]
        end
        format.html { redirect_to @travel_plan, notice: "Travel plan was successfully created." }
        format.json { render :show, status: :created, location: @travel_plan }
      else
        # If save fails, re-render the recommendations page with an error.
        # This prevents losing the context of the recommendations.
        flash.now[:alert] = @travel_plan.errors.full_messages.to_sentence
        @recommendations = current_user.recommendations_json || []
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("notifications", 
                                                     partial: "shared/error_notification",
                                                     locals: { message: @travel_plan.errors.full_messages.to_sentence })
        end
        format.html { render 'travel_recommendations/index', status: :unprocessable_entity }
        format.json { render json: @travel_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /travel_plans/1 or /travel_plans/1.json
  def update
    respond_to do |format|
      if @travel_plan.update(travel_plan_params)
        format.html { redirect_to @travel_plan, notice: "Travel plan was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @travel_plan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @travel_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /travel_plans/1 or /travel_plans/1.json
  def destroy
    @travel_plan.destroy!

    respond_to do |format|
      format.html { redirect_to travel_plans_path, notice: "Travel plan was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_travel_plan
    @travel_plan = current_user.travel_plans.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def travel_plan_params
    # Permit the attributes sent from the AI recommendation hash.
    # The itinerary and budget_breakdown are serialized as JSON.
    # Note: destination_name is excluded here because it's only used to find/create destinations
    params.require(:travel_plan).permit(
      :name, :description, :details, :budget_min, :budget_max,
      :safety_score, :safety_level, :travel_style, :length_of_stay, :travel_month,
      :trip_scope, :trip_type, :general_purpose, :status, :notes,
      :visa_info, :safety_preference, :start_date, :end_date, 
      :passport_country, :current_location, :destination_country,
      itinerary: {}, budget_breakdown: {}, safety_levels: []
    )
  end

  def require_login
    unless logged_in?
      flash[:alert] = "You must be logged in to access this section."
      redirect_to login_path
    end
  end

  # Find or create a destination based on recommendation data
  def find_or_create_destination_from_params
    # Return nil if travel_plan params don't exist
    return nil unless params[:travel_plan].present?
    
    destination_name = params[:travel_plan][:destination_name] || params[:travel_plan][:name]
    destination_city = params[:travel_plan][:destination_city] || destination_name
    destination_country = params[:travel_plan][:destination_country]
    
    return nil unless destination_name && destination_country
    
    # Try to find existing destination by name and country
    destination = Destination.find_by(
      name: destination_name,
      country: destination_country
    )
    
    # Create new destination if not found
    unless destination
      # Convert safety_level to numeric safety_score for backward compatibility
      safety_score_value = if params[:travel_plan][:safety_level].present?
        case params[:travel_plan][:safety_level]
        when "level_1" then 9
        when "level_2" then 7
        when "level_3" then 4
        when "level_4" then 2
        else 5
        end
      else
        params[:travel_plan][:safety_score]&.to_i
      end
      
      # Calculate average cost from budget
      average_cost = if params[:travel_plan][:budget_min].present? && params[:travel_plan][:budget_max].present?
        (params[:travel_plan][:budget_min].to_f + params[:travel_plan][:budget_max].to_f) / 2
      elsif params[:travel_plan][:average_cost].present?
        params[:travel_plan][:average_cost].to_f
      else
        nil
      end
      
      # Get best season from travel_month
      best_season = params[:travel_plan][:travel_month] || params[:travel_plan][:best_season]
      
      destination = Destination.create(
        name: destination_name,
        city: destination_city,
        country: destination_country,
        description: params[:travel_plan][:description],
        safety_score: safety_score_value,
        visa_required: params[:travel_plan][:visa_info]&.downcase&.include?('required'),
        average_cost: average_cost,
        best_season: best_season
        # Note: latitude and longitude will be auto-geocoded by the Destination model
        # based on the city and country (or name and country if city is blank) through the geocoded_by callback
      )
    end
    
    destination
  end

  # Set default dates based on travel_month and length_of_stay
  def set_default_dates
    if @travel_plan.travel_month.present? && @travel_plan.length_of_stay.present?
      # Parse the travel month to get a date
      month_map = {
        'january' => 1, 'february' => 2, 'march' => 3, 'april' => 4,
        'may' => 5, 'june' => 6, 'july' => 7, 'august' => 8,
        'september' => 9, 'october' => 10, 'november' => 11, 'december' => 12
      }
      
      month_num = month_map[@travel_plan.travel_month.downcase]
      if month_num
        year = Date.today.year
        year += 1 if month_num < Date.today.month # If the month has passed, use next year
        
        @travel_plan.start_date ||= Date.new(year, month_num, 1)
        @travel_plan.end_date ||= @travel_plan.start_date + @travel_plan.length_of_stay.days
      end
    end
    
    # Fallback: use today and a week from now
    @travel_plan.start_date ||= Date.today
    @travel_plan.end_date ||= Date.today + 7.days
  end
end
