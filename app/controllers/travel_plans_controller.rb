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
    # Find or create destination based on recommendation data
    destination = find_or_create_destination_from_params
    
    # Build travel plan with the destination
    @travel_plan = current_user.travel_plans.build(travel_plan_params)
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
      :safety_score, :travel_style, :length_of_stay, :travel_month,
      :trip_scope, :trip_type, :general_purpose, :status, :notes,
      :visa_info, :safety_preference, :start_date, :end_date, 
      :passport_country, :destination_country,
      itinerary: {}, budget_breakdown: {}
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
    destination_name = params[:travel_plan][:destination_name] || params[:travel_plan][:name]
    destination_country = params[:travel_plan][:destination_country]
    
    return nil unless destination_name && destination_country
    
    # Try to find existing destination
    destination = Destination.find_by(
      name: destination_name,
      country: destination_country
    )
    
    # Create new destination if not found
    unless destination
      destination = Destination.create(
        name: destination_name,
        country: destination_country,
        description: params[:travel_plan][:description],
        safety_score: params[:travel_plan][:safety_score]&.to_i,
        visa_required: params[:travel_plan][:visa_info]&.downcase&.include?('required')
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
