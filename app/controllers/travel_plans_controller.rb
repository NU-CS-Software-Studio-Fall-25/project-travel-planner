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
    @travel_plan = current_user.travel_plans.build(travel_plan_params)

    respond_to do |format|
      if @travel_plan.save
        format.html { redirect_to @travel_plan, notice: "Travel plan was successfully created." }
        format.json { render :show, status: :created, location: @travel_plan }
      else
        # If save fails, re-render the recommendations page with an error.
        # This prevents losing the context of the recommendations.
        flash.now[:alert] = @travel_plan.errors.full_messages.to_sentence
        @recommendations = session.fetch(:recommendations, [])
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
    params.require(:travel_plan).permit(
      :name, :description, :details, :budget_min, :budget_max,
      :safety_score, :travel_style, :length_of_stay, :travel_month,
      :trip_scope, :trip_type, :general_purpose,
      itinerary: {}, budget_breakdown: {}
    )
  end

  def require_login
    unless logged_in?
      flash[:alert] = "You must be logged in to access this section."
      redirect_to login_path
    end
  end
end
