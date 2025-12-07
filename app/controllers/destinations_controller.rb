class DestinationsController < ApplicationController
  before_action :set_destination, only: %i[ show edit update destroy ]

  # GET /destinations or /destinations.json
  def index
    all = Destination.all

    # Filter by name search
    if params[:search].present?
      all = all.where("name LIKE ? OR country LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Filter by country (domestic/international)
    if params[:country_filter].present? && params[:country_filter] != "all"
      if current_user&.current_country.present?
        if params[:country_filter] == "domestic"
          all = all.where(country: current_user.current_country)
        elsif params[:country_filter] == "international"
          all = all.where.not(country: current_user.current_country)
        end
      end
    end

    # Filter by visa requirement
    if params[:visa_filter].present? && params[:visa_filter] != "all"
      if params[:visa_filter] == "not_required"
        # Include domestic destinations (always no visa) and international destinations without visa
        if current_user&.current_country.present?
          all = all.where("country = ? OR visa_required = ?", current_user.current_country, false)
        else
          all = all.where(visa_required: false)
        end
      elsif params[:visa_filter] == "required"
        # Only international destinations with visa required
        if current_user&.current_country.present?
          all = all.where.not(country: current_user.current_country).where(visa_required: true)
        else
          all = all.where(visa_required: true)
        end
      end
    end

    # Sort by safety score
    if params[:safety_sort].present? && params[:safety_sort] != "default"
      if params[:safety_sort] == "high_to_low"
        all = all.order(safety_score: :desc, name: :asc)
      elsif params[:safety_sort] == "low_to_high"
        all = all.order(safety_score: :asc, name: :asc)
      end
    else
      all = all.order(:name)
    end

    # Pagination for all destinations (25 per page)
    @pagy, @destinations = pagy(all, items: 25)
  end

  # GET /destinations/1 or /destinations/1.json
  def show
  end

  # GET /destinations/new
  def new
    @destination = Destination.new
  end

  # GET /destinations/1/edit
  def edit
  end

  # POST /destinations or /destinations.json
  def create
    @destination = Destination.new(destination_params)

    respond_to do |format|
      if @destination.save
        format.html { redirect_to @destination, notice: "Destination was successfully created." }
        format.json { render :show, status: :created, location: @destination }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @destination.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /destinations/1 or /destinations/1.json
  def update
    respond_to do |format|
      if @destination.update(destination_params)
        format.html { redirect_to @destination, notice: "Destination was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @destination }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @destination.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /destinations/1 or /destinations/1.json
  def destroy
    @destination.destroy!

    respond_to do |format|
      format.html { redirect_to destinations_path, notice: "Destination was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_destination
      @destination = Destination.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def destination_params
      params.require(:destination).permit(:name, :city, :country, :description, :visa_required, :safety_score, :best_season, :average_cost, :latitude, :longitude)
    end
end
