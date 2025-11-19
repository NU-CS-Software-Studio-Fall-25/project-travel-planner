# app/controllers/travel_plans_controller.rb
require 'prawn'
require 'prawn/table'
class TravelPlansController < ApplicationController
  include Pagy::Backend if defined?(Pagy::Backend)
  before_action :set_travel_plan, only: %i[ show edit update destroy ]
  before_action :require_login

  # ruby
  def download_pdf
    # Ensure users can only download PDFs for their own travel plans
    travel_plan = current_user.travel_plans.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Travel plan not found or you don't have permission to access it."
    redirect_to travel_plans_path and return
  else
    trip_days = if travel_plan.start_date && travel_plan.end_date
                  ((travel_plan.end_date - travel_plan.start_date).to_i + 1)
                else
                  1
                end
    travelers = travel_plan.number_of_travelers.to_i.nonzero? || 1

    # Leave extra bottom margin for footer (top, right, bottom, left)
    pdf = Prawn::Document.new(page_size: 'A4', margin: [50, 50, 80, 50])

    # Safe font selection (use TTF if available, otherwise a built-in)
    ttf_path = File.join(Prawn::DATADIR, 'fonts', 'DejaVuSans.ttf')
    if File.exist?(ttf_path)
      pdf.font_families.update("DejaVuSans" => { normal: ttf_path })
      pdf.font "DejaVuSans"
    else
      pdf.font "Helvetica"
    end

    # Header
    pdf.text (travel_plan.name.presence || "#{travel_plan.destination&.name || 'Trip'}"), size: 20, style: :bold
    pdf.move_down 6
    if travel_plan.destination&.country
      pdf.text "#{travel_plan.destination.country}", size: 10, color: "555555"
    end
    pdf.move_down 8
    pdf.stroke_horizontal_rule
    pdf.move_down 12

    # Trip summary
    pdf.text "Trip Summary", size: 14, style: :bold
    pdf.move_down 6
    pdf.text "Dates: #{travel_plan.start_date&.strftime('%B %d, %Y') || 'N/A'} - #{travel_plan.end_date&.strftime('%B %d, %Y') || 'N/A'}"
    pdf.text "Status: #{travel_plan.status&.titleize || 'N/A'}"
    pdf.text "Travel Style: #{travel_plan.travel_style}" if travel_plan.travel_style.present?
    pdf.move_down 8

    # Description/Notes
    if travel_plan.description.present?
      pdf.text "Description", style: :bold
      pdf.move_down 4
      pdf.text travel_plan.description.to_s, size: 10
      pdf.move_down 8
    end
    if travel_plan.notes.present?
      pdf.text "Notes", style: :bold
      pdf.move_down 4
      pdf.text travel_plan.notes.to_s, size: 10
      pdf.move_down 8
    end

    # Itinerary
    if travel_plan.itinerary.present?
      pdf.start_new_page if pdf.cursor < 180
      pdf.text "Itinerary", size: 14, style: :bold
      pdf.move_down 8
      if travel_plan.itinerary.is_a?(Hash)
        travel_plan.itinerary.each do |day, activities|
          pdf.text day.to_s.titleize, style: :bold, size: 11
          pdf.move_down 4
          if activities.is_a?(Array)
            activities.each { |a| pdf.text "\u2022 #{a}", size: 10, indent_paragraphs: 8 }
          else
            pdf.text activities.to_s, size: 10, indent_paragraphs: 8
          end
          pdf.move_down 8
          pdf.start_new_page if pdf.cursor < 140
        end
      else
        pdf.text travel_plan.itinerary.to_s, size: 10
      end
    end

    # Budget breakdown: build structured rows
    if travel_plan.budget_breakdown.present?
      pdf.start_new_page if pdf.cursor < 180
      pdf.text "Budget Breakdown", size: 14, style: :bold
      pdf.move_down 8

      rows = [["Category", "Unit Price", "Quantity", "Total", "Note"]]
      grand_total = 0.0

      travel_plan.budget_breakdown.each do |category, data|
        next if category.to_s.downcase.include?("total_trip_cost") || category.to_s.strip.empty?

        unit = nil
        qty = 1
        total = nil
        note = nil

        if data.is_a?(Hash)
          # extract numeric values (prefer explicit keys)
          # keys may be symbols or strings
          h = data.transform_keys(&:to_s)
          # parse potential unit costs
          unit_candidates = %w[cost cost_per_person cost_per_day_per_person cost_per_day cost_per_night cost_per_day_total cost_per_night cost_per_day_per_person]
          unit_key = unit_candidates.find { |k| h[k].present? }
          if unit_key
            unit_value = h[unit_key].to_s.gsub(/[^\d\.]/, '').to_f
          else
            unit_value = nil
          end

          # total cost explicit
          if h["total_cost"].present? && (v = h["total_cost"].to_s.gsub(/[^\d\.]/, '')).present?
            total = v.to_f
          end

          # description note
          note = (h["description"] || h["note"] || "").to_s.strip

          # determine quantity based on which unit key present
          case unit_key
          when "cost_per_person"
            qty = travelers
            unit = unit_value ? sprintf("$%0.2f / person", unit_value) : nil
          when "cost_per_day_per_person", "cost_per_day_per_person"
            qty = travelers * trip_days
            unit = unit_value ? sprintf("$%0.2f / day/person", unit_value) : nil
          when "cost_per_day_total", "cost_per_day_total"
            qty = trip_days
            unit = unit_value ? sprintf("$%0.2f / day (total)", unit_value) : nil
          when "cost_per_night"
            # nights: typical convention = days - 1, but fallback to days
            nights = [trip_days - 1, 1].max
            qty = nights
            unit = unit_value ? sprintf("$%0.2f / night", unit_value) : nil
          when "cost_per_day"
            qty = trip_days
            unit = unit_value ? sprintf("$%0.2f / day", unit_value) : nil
          when "cost"
            qty = 1
            unit = unit_value ? sprintf("$%0.2f", unit_value) : nil
          else
            # fallback: try to parse any number-like tokens for a total or unit
            if unit_value && unit_value > 0
              unit = sprintf("$%0.2f", unit_value)
              qty = 1
            end
          end

          # compute total if still nil
          if total.nil?
            if unit && unit_value
              total = unit_value * qty
            else
              # fallback: try to locate any numeric in values
              any_num = h.values.map { |v| v.to_s.gsub(/[^\d\.]/, '') }.find(&:present?)
              total = any_num.to_f if any_num
            end
          end
        else
          # data is a string: try to parse total_cost or numbers
          s = data.to_s
          if (m = s.match(/total[_\s]*cost[:\s]*\$?(\d+(?:\.\d+)?)/i))
            total = m[1].to_f
          elsif (m = s.match(/cost[_\s]*per[_\s]*person[:\s]*\$?(\d+(?:\.\d+)?)/i))
            unit = sprintf("$%0.2f / person", m[1].to_f)
            qty = travelers
            total = m[1].to_f * qty
          elsif (m = s.match(/cost[:\s]*\$?(\d+(?:\.\d+)?)/i))
            unit = sprintf("$%0.2f", m[1].to_f)
            qty = 1
            total = m[1].to_f
          else
            # final fallback: pick first numeric token as total
            num = s.gsub(/[^\d\.]/, '')
            total = num.present? ? num.to_f : 0.0
          end
          # note: keep human-readable portion but strip raw keys like _ or `total_cost`
          note = s.gsub(/(_|\b(total[_\s]*cost|cost[_\s]*per[_\s]*person|cost[_\s]*per[_\s]*day[_\s]*per[_\s]*person|cost[_\s]*per[_\s]*day|cost[_\s]*per[_\s]*night)\b[:\s]*\$?\d*\.?\d*)/i, '').strip
        end

        unit_display = unit || "-"
        qty_display = qty.to_i == qty ? qty.to_i : qty
        total ||= 0.0
        grand_total += total

        rows << [
          category.to_s.titleize,
          unit_display,
          qty_display.to_s,
          sprintf("$%0.2f", total),
          (note.presence || "-")
        ]
      end

      # Render table
      pdf.table(rows, header: true, width: pdf.bounds.width) do
        row(0).font_style = :bold
        row(0).background_color = 'f0f0f0'
        columns(1..3).align = :right
        self.row_colors = ['FFFFFF', 'F9F9F9']
        self.cell_style = { borders: [:bottom], border_width: 0.5, border_color: 'DDDDDD', padding: [6,8,6,8], size: 10 }
      end

      pdf.move_down 8
      pdf.text "Grand Total: #{sprintf('$%0.2f', grand_total)}", size: 12, style: :bold, align: :right
    end

    # Footer: rendered on every page in reserved bottom area to avoid overlap
    timestamp = Time.current.strftime('%Y-%m-%d %H:%M')
    pdf.repeat(:all) do
      pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom + 50], width: pdf.bounds.width) do
        pdf.stroke_horizontal_rule
        pdf.move_down 4
        pdf.font_size 8
        pdf.text "Generated: #{timestamp}", align: :left
        pdf.text "Page <page> of <total>", align: :right, inline_format: true
      end
    end

    filename = "#{(travel_plan.name.presence || "travel_plan_#{travel_plan.id}")}.pdf"
    send_data pdf.render, filename: filename, type: 'application/pdf', disposition: 'attachment'
  end


  # GET /travel_plans or /travel_plans.json
  def index
    @pagy, @travel_plans = pagy(current_user.travel_plans.order(created_at: :desc), items: 10)
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
