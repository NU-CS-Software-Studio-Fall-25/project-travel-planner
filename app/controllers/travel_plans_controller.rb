class TravelPlansController < ApplicationController
  before_action :set_travel_plan, only: %i[ show edit update destroy ]

  # GET /travel_plans or /travel_plans.json
  def index
    @travel_plans = TravelPlan.all
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
    @travel_plan = TravelPlan.new(travel_plan_params)

    respond_to do |format|
      if @travel_plan.save
        format.html { redirect_to @travel_plan, notice: "Travel plan was successfully created." }
        format.json { render :show, status: :created, location: @travel_plan }
      else
        format.html { render :new, status: :unprocessable_entity }
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
      @travel_plan = TravelPlan.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def travel_plan_params
      params.expect(travel_plan: [ :user_id, :destination_id, :start_date, :end_date, :status, :notes ])
    end
end
