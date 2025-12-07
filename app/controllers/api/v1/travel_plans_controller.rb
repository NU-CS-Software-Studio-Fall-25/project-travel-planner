class Api::V1::TravelPlansController < Api::V1::BaseController
  before_action :set_travel_plan, only: [ :show, :update, :destroy ]

  # GET /api/v1/travel_plans
  def index
    @travel_plans = TravelPlan.includes(:user, :destination).all

    # Filter by user if specified
    @travel_plans = @travel_plans.where(user_id: params[:user_id]) if params[:user_id].present?

    render_success(@travel_plans.as_json(include: [ :user, :destination ]))
  end

  # GET /api/v1/travel_plans/1
  def show
    render_success(@travel_plan.as_json(include: [ :user, :destination ]))
  end

  # POST /api/v1/travel_plans
  def create
    @travel_plan = TravelPlan.new(travel_plan_params)

    if @travel_plan.save
      render_success(@travel_plan.as_json(include: [ :user, :destination ]), "Travel plan created successfully")
    else
      render_error(@travel_plan.errors.full_messages.join(", "))
    end
  end

  # PATCH/PUT /api/v1/travel_plans/1
  def update
    if @travel_plan.update(travel_plan_params)
      render_success(@travel_plan.as_json(include: [ :user, :destination ]), "Travel plan updated successfully")
    else
      render_error(@travel_plan.errors.full_messages.join(", "))
    end
  end

  # DELETE /api/v1/travel_plans/1
  def destroy
    @travel_plan.destroy!
    render_success({}, "Travel plan deleted successfully")
  end

  private

  def set_travel_plan
    @travel_plan = TravelPlan.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("Travel plan not found")
  end

  def travel_plan_params
    params.require(:travel_plan).permit(:user_id, :destination_id, :start_date, :end_date, :status, :notes)
  end
end
