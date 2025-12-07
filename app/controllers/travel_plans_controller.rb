# app/controllers/travel_plans_controller.rb
require "prawn"
require "prawn/table"
class TravelPlansController < ApplicationController
  include Pagy::Backend if defined?(Pagy::Backend)
  before_action :set_travel_plan, only: %i[ show edit update destroy ]
  before_action :require_login

  # ruby
  def download_pdf
    travel_plan = current_user.travel_plans.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Travel plan not found or you don't have permission to access it."
    redirect_to travel_plans_path and return
  else
    # --- CONFIGURATION ---
    theme_color   = "1A3B5D" # Professional Navy
    accent_color  = "F0F4F8" # Very light blue/grey for backgrounds
    text_color    = "333333" # Dark Grey

    pdf = Prawn::Document.new(page_size: "A4", margin: [ 50, 50, 50, 50 ])

    # --- FONTS ---
    ttf_path = File.join(Prawn::DATADIR, "fonts", "DejaVuSans.ttf")
    if File.exist?(ttf_path)
      pdf.font_families.update("DejaVuSans" => { normal: ttf_path })
      pdf.font "DejaVuSans"
    else
      pdf.font "Helvetica"
    end

    # --- HELPER METHODS ---
    def draw_section_header(pdf, title, color)
      pdf.move_down 20
      pdf.text title.upcase, size: 12, style: :bold, color: color, character_spacing: 1
      pdf.stroke do
        pdf.stroke_color color
        pdf.line_width 1
        pdf.horizontal_line pdf.bounds.left, pdf.bounds.width, at: pdf.cursor - 5
      end
      pdf.move_down 15
    end

    # =====================
    # HEADER
    # =====================
    pdf.fill_color theme_color
    pdf.text (travel_plan.name.presence || "Travel Plan"), size: 26, style: :bold

    if travel_plan.destination
      pdf.move_down 5
      pdf.text "#{travel_plan.destination.city}, #{travel_plan.destination.country}".upcase,
               size: 10, color: "777777", character_spacing: 1.5
    end

    pdf.move_down 20

    # =====================
    # TRIP SUMMARY (Boxed Style)
    # =====================
    summary_height = 60
    pdf.bounding_box([ 0, pdf.cursor ], width: pdf.bounds.width, height: summary_height) do
      pdf.fill_color accent_color
      pdf.fill_rectangle [ 0, pdf.bounds.height ], pdf.bounds.width, pdf.bounds.height

      pdf.fill_color text_color

      pdf.indent(10) do
        pdf.move_down 10
        summary_data = [
          [
            "DATES",
            "#{travel_plan.start_date&.strftime('%b %d, %Y') || 'TBD'}  -  #{travel_plan.end_date&.strftime('%b %d, %Y') || 'TBD'}"
          ],
          [
            "STYLE",
            travel_plan.travel_style.presence || "General"
          ]
        ]

        pdf.table(summary_data, width: pdf.bounds.width - 20) do
          cells.borders = []
          cells.padding = [ 2, 0 ]
          column(0).font_style = :bold
          column(0).size = 9
          column(0).text_color = theme_color
          column(0).width = 60
          column(1).size = 10
        end
      end
    end

    pdf.move_down 20

    # =====================
    # DESCRIPTION & NOTES
    # =====================
    if travel_plan.description.present?
      draw_section_header(pdf, "Overview", theme_color)
      pdf.text travel_plan.description.to_s, size: 10, leading: 4, color: text_color, align: :justify
    end

    if travel_plan.notes.present?
      pdf.move_down 10
      pdf.text "<b>Note:</b> #{travel_plan.notes}", size: 10, leading: 4, inline_format: true, color: "555555"
    end

    # =====================
    # ITINERARY (Fixed: Removed pdf.group)
    # =====================
    if travel_plan.itinerary.present?
      # Ensure we don't start the section too low on the page
      pdf.start_new_page if pdf.cursor < 200
      draw_section_header(pdf, "Itinerary", theme_color)

      if travel_plan.itinerary.is_a?(Hash)
        travel_plan.itinerary.each do |day, activities|
          # --- LOGIC FIX ---
          # Estimate height needed for this block:
          # Header (~20pts) + Spacing (~10pts) + Lines of text (~15pts per line)
          lines_count = activities.is_a?(Array) ? activities.length : 2
          height_needed = 40 + (lines_count * 15)

          # If current cursor position is lower than height needed, force new page
          pdf.start_new_page if pdf.cursor < height_needed
          # -----------------

          pdf.move_down 10

          # Day Header
          pdf.text day.to_s.upcase, size: 11, style: :bold, color: theme_color

          # Content
          pdf.indent(15) do
            pdf.move_down 5
            if activities.is_a?(Array)
              activities.each do |a|
                pdf.text "•  #{a}", size: 10, leading: 3, color: text_color
              end
            else
              pdf.text activities.to_s, size: 10, leading: 3, color: text_color
            end
          end

          pdf.move_down 10
        end
      else
        pdf.text travel_plan.itinerary.to_s, size: 10, leading: 3
      end
    end

    # =====================
    # BUDGET BREAKDOWN
    # =====================
    if travel_plan.budget_breakdown.present?
      pdf.start_new_page if pdf.cursor < 250
      draw_section_header(pdf, "Estimated Budget", theme_color)

      rows = [ [ "CATEGORY", "NOTE", "TOTAL" ] ]
      grand_total = 0.0

      travel_plan.budget_breakdown.each do |category, data|
        next if category.to_s.downcase.include?("total_trip_cost") || category.to_s.strip.empty?

        total = nil
        note  = nil

        if data.is_a?(Hash)
          h = data.transform_keys(&:to_s)
          if h["total_cost"].present?
            total = h["total_cost"].to_s.gsub(/[^\d\.]/, "").to_f
          else
            any_num = h.values.map { |v| v.to_s.gsub(/[^\d\.]/, "") }.find(&:present?)
            total = any_num.to_f
          end
          raw_note = (h["description"] || h["note"] || "").to_s.strip
          note = raw_note.gsub(/\bdescription\b/i, "").strip
        else
          s = data.to_s
          if (m = s.match(/total[_\s]*cost[:\s]*\$?(\d+(?:\.\d+)?)/i))
            total = m[1].to_f
          else
            total = s.gsub(/[^\d\.]/, "").to_f
          end
          note = s.gsub(/description|total[_\s]*cost.*|cost.*/i, "").strip
        end

        total ||= 0.0
        grand_total += total

        rows << [
          category.to_s.titleize,
          (note.presence || "-"),
          "$#{'%.2f' % total}"
        ]
      end

      pdf.table(rows, header: true, width: pdf.bounds.width) do
        cells.style(size: 9, padding: [ 8, 10 ], border_width: 0, text_color: text_color)

        row(0).style(
          background_color: theme_color,
          text_color: "FFFFFF",
          font_style: :bold,
          borders: [ :bottom ],
          border_width: 0
        )

        rows(1..-1).each_with_index do |row, index|
          row.background_color = index.odd? ? "FFFFFF" : accent_color
        end

        column(0).width = 120
        column(0).font_style = :bold
        column(2).align = :right
        column(2).width = 80
        column(2).font_style = :bold
      end

      pdf.move_down 15

      pdf.indent(pdf.bounds.width - 200) do
        pdf.text "TOTAL ESTIMATE", size: 10, align: :right, color: "777777"
        pdf.text "$#{'%.2f' % grand_total}", size: 18, style: :bold, align: :right, color: theme_color
      end
    end

    # =====================
    # FOOTER
    # =====================
    pdf.number_pages "Page <page> of <total>", {
      start_count_at: 1,
      page_filter: :all,
      at: [ pdf.bounds.right - 150, 0 ],
      align: :right,
      size: 8,
      color: "999999"
    }

    filename = "#{travel_plan.name.presence || "travel_plan_#{travel_plan.id}"}.pdf"
    send_data pdf.render, filename: filename, type: "application/pdf", disposition: "attachment"
  end

  # GET /travel_plans or /travel_plans.json
  def index
    # Separate plans into future and past based on end_date
    all_plans = current_user.travel_plans.order(created_at: :desc)
    
    @future_plans = all_plans.where("end_date >= ?", Date.today).or(all_plans.where(end_date: nil))
    @past_plans = all_plans.where("end_date < ?", Date.today)
    
    # Keep pagination for backward compatibility if needed
    @pagy, @travel_plans = pagy(all_plans, items: 10)
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

    # Remove destination fields from plan_params as they're handled separately
    plan_params.delete(:destination_name)
    plan_params.delete(:destination_country)

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
        # If save fails, re-render the form with errors
        flash.now[:alert] = @travel_plan.errors.full_messages.to_sentence
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("notifications",
                                                     partial: "shared/error_notification",
                                                     locals: { message: @travel_plan.errors.full_messages.to_sentence })
        end
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
    # Ensure users can only access their own travel plans (prevents unauthorized access)
    @travel_plan = current_user.travel_plans.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Travel plan not found or you don't have permission to access it."
    redirect_to travel_plans_path
  end

  # Only allow a list of trusted parameters through.
  def travel_plan_params
    # Permit the attributes sent from the AI recommendation hash.
    # The itinerary and budget_breakdown are serialized as JSON.
    # Note: destination_name is excluded here because it's only used to find/create destinations
    params.require(:travel_plan).permit(
      :name, :description, :details, :budget_min, :budget_max,
      :safety_score, :safety_level, :travel_style, :length_of_stay, :travel_month,
      :trip_scope, :number_of_travelers, :general_purpose, :status, :notes,
      :visa_info, :safety_preference, :start_date, :end_date,
      :passport_country, :current_location, :destination_country, :destination_name,
      :destination_id,
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

    # If a destination_id is selected, use that (validate it's a valid ID)
    if params[:travel_plan][:destination_id].present?
      destination_id = params[:travel_plan][:destination_id].to_i
      return Destination.find_by(id: destination_id) if destination_id > 0
    end

    # Otherwise, try to create from destination_name and destination_country
    # Sanitize inputs to prevent XSS and injection attacks
    destination_name = ActionController::Base.helpers.sanitize(params[:travel_plan][:destination_name]&.strip)
    destination_country = ActionController::Base.helpers.sanitize(params[:travel_plan][:destination_country]&.strip)

    # Return nil if no destination info provided (it's optional now)
    return nil unless destination_name.present? && destination_country.present?

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
        params[:travel_plan][:safety_score]&.to_i || 5
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
        city: destination_name,
        country: destination_country,
        description: params[:travel_plan][:description],
        safety_score: safety_score_value,
        visa_required: params[:travel_plan][:visa_info]&.downcase&.include?("required"),
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
        "january" => 1, "february" => 2, "march" => 3, "april" => 4,
        "may" => 5, "june" => 6, "july" => 7, "august" => 8,
        "september" => 9, "october" => 10, "november" => 11, "december" => 12
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
