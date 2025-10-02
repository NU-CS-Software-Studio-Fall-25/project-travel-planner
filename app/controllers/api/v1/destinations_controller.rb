class Api::V1::DestinationsController < Api::V1::BaseController
  before_action :set_destination, only: [:show, :update, :destroy]

  # GET /api/v1/destinations
  def index
    @destinations = Destination.all
    
    # Apply filters if provided
    @destinations = @destinations.safe_destinations(params[:min_safety]) if params[:min_safety].present?
    @destinations = @destinations.visa_not_required if params[:visa_free] == 'true'
    @destinations = @destinations.by_season(params[:season]) if params[:season].present?
    
    render_success(@destinations)
  end

  # GET /api/v1/destinations/1
  def show
    render_success(@destination)
  end

  # POST /api/v1/destinations
  def create
    @destination = Destination.new(destination_params)

    if @destination.save
      render_success(@destination, "Destination created successfully")
    else
      render_error(@destination.errors.full_messages.join(", "))
    end
  end

  # PATCH/PUT /api/v1/destinations/1
  def update
    if @destination.update(destination_params)
      render_success(@destination, "Destination updated successfully")
    else
      render_error(@destination.errors.full_messages.join(", "))
    end
  end

  # DELETE /api/v1/destinations/1
  def destroy
    @destination.destroy!
    render_success({}, "Destination deleted successfully")
  end

  private

  def set_destination
    @destination = Destination.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("Destination not found")
  end

  def destination_params
    params.require(:destination).permit(:name, :country, :description, :visa_required, :safety_score, :best_season, :average_cost, :latitude, :longitude)
  end
end