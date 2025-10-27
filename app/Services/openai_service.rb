# app/Services/openai_service.rb
require 'openai'

class OpenaiService
  def initialize(preferences)
    @client = OpenAI::Client.new(api_key: ENV.fetch('OPENAI_API_KEY'))
    @preferences = preferences
  end

  def get_recommendations
    prompt = build_prompt

    begin
      Rails.logger.info "=== OpenAI API Call Starting ==="
      Rails.logger.info "API Key present: #{ENV['OPENAI_API_KEY'].present?}"
      Rails.logger.info "API Key length: #{ENV['OPENAI_API_KEY']&.length}"
      
      response = @client.chat.completions.create(
        model: "gpt-4o",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_tokens: 7000,
        response_format: { type: "json_object" }
      )

      Rails.logger.info "=== OpenAI Response Received ==="
      Rails.logger.info "Response: #{response.inspect}"
      
      # Parse the response and return it
      parse_response(response)
    rescue => e
      Rails.logger.error "=== OpenAI API Error ==="
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Error message: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
      
      # Return an error recommendation
      [{
        name: "API Error",
        destination_country: "Error",
        description: "Failed to get recommendations from OpenAI: #{e.message}",
        details: "Please check your API key and try again. Error: #{e.class}",
        itinerary: {},
        budget_min: 0,
        budget_max: 0,
        budget_breakdown: {},
        safety_level: "level_1",
        travel_style: "N/A",
        visa_info: "N/A",
        length_of_stay: @preferences[:length_of_stay]&.to_i || 4,
        travel_month: @preferences[:travel_month] || "Unknown",
        trip_scope: @preferences[:trip_scope] || "Unknown",
        trip_type: @preferences[:trip_type] || "Unknown",
        general_purpose: @preferences[:general_purpose] || "Unknown",
        start_date: @preferences[:start_date],
        end_date: @preferences[:end_date]
      }]
    end
  end

  private

  # Get eligible countries based on user's safety preference from GPI database
  def get_safe_countries(safety_preference)
    return CountrySafetyScore.all if safety_preference.blank?
    
    countries = CountrySafetyScore.for_safety_level(safety_preference)
    
    # Filter by trip scope if needed
    if @preferences[:trip_scope] == "Domestic" && @preferences[:passport_country].present?
      # For domestic trips, check if home country meets safety criteria
      home_country = CountrySafetyScore.find_by(country_name: @preferences[:passport_country], year: 2025)
      
      if home_country && countries.exists?(country_name: @preferences[:passport_country])
        # Home country meets the safety criteria
        countries = countries.where(country_name: @preferences[:passport_country])
      elsif home_country
        # Home country exists but doesn't meet safety criteria - include it anyway for domestic trips
        # but note the actual safety level
        Rails.logger.warn "Domestic trip: Including #{@preferences[:passport_country]} (GPI: #{home_country.gpi_score}, #{home_country.safety_level}) even though it doesn't meet '#{safety_preference}' criteria"
        countries = CountrySafetyScore.where(country_name: @preferences[:passport_country])
      else
        # Home country not in database - return empty to trigger appropriate message
        countries = CountrySafetyScore.none
      end
    elsif @preferences[:trip_scope] == "International" && @preferences[:passport_country].present?
      # For international trips, exclude the user's home country
      countries = countries.where.not(country_name: @preferences[:passport_country])
    end
    
    countries
  end
  
  # Build detailed safety context with GPI data for the LLM
  def build_safety_context(safety_preference)
    countries = get_safe_countries(safety_preference)
    
    if countries.empty?
      return {
        country_list: "No countries available",
        country_count: 0,
        country_details: "No countries match the selected criteria.",
        restriction_note: "Please adjust your preferences.",
        safety_level: safety_preference
      }
    end
    
    # Get country names for the restriction
    country_names = countries.pluck(:country_name).sort
    
    # Get detailed info for top countries (to give LLM context)
    top_countries = countries.order(:gpi_rank).limit(10)
    country_details = top_countries.map do |c|
      "#{c.country_name} (GPI: #{c.gpi_score}, Rank: ##{c.gpi_rank}/163, #{c.safety_level})"
    end.join("\n       ")
    
    # Check if this is a domestic trip where home country doesn't meet preferred safety level
    safety_note = "Based on 2025 Global Peace Index data"
    if @preferences[:trip_scope] == "Domestic" && countries.count == 1
      home_country = countries.first
      if home_country.safety_level != safety_preference
        safety_note = "NOTE: #{home_country.country_name} is classified as '#{home_country.safety_level}' (GPI: #{home_country.gpi_score}), which is different from your '#{safety_preference}' preference. For domestic travel, recommendations will be provided within your home country."
      end
    end
    
    {
      country_list: country_names.join(", "),
      country_count: countries.count,
      country_details: country_details,
      safety_level: safety_preference,
      top_country: top_countries.first,
      restriction_note: safety_note
    }
  end

  def build_prompt
    # Calculate date information
    start_date = @preferences[:start_date].present? ? Date.parse(@preferences[:start_date].to_s) : nil
    end_date = @preferences[:end_date].present? ? Date.parse(@preferences[:end_date].to_s) : nil
    length_of_stay = @preferences[:length_of_stay] || 
                     (start_date && end_date ? (end_date - start_date).to_i + 1 : 4)
    travel_month = @preferences[:travel_month] || (start_date ? start_date.strftime("%B") : "")
    
    # Format dates for the prompt
    date_range = if start_date && end_date
                   "#{start_date.strftime('%B %d, %Y')} to #{end_date.strftime('%B %d, %Y')}"
                 elsif travel_month.present?
                   "during #{travel_month}"
                 else
                   "within the next few months"
                 end
    
    # Get safety context from GPI database
    safety_preference = @preferences[:safety_preference]
    safety_context = build_safety_context(safety_preference)
    
    <<~PROMPT
      You are a professional travel planner. Based on the following travel preferences, suggest 5 travel destinations that STRICTLY match ALL the user's requirements.

      CRITICAL REQUIREMENTS - ALL recommendations MUST:
      1. Have itineraries for EXACTLY #{length_of_stay} days (no more, no less)
      2. Be suitable for travel #{date_range} (consider weather, seasonal events, holidays, and typical conditions for this specific time period)
      3. Fit within the budget range of $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]} (budget_min and budget_max MUST be within this range)
      4. Match the #{@preferences[:trip_scope]} scope (only suggest #{@preferences[:trip_scope]} destinations)
      5. Be appropriate for #{@preferences[:trip_type]} travelers
      6. Follow the #{@preferences[:travel_style]} travel style
      
      ⚠️ CRITICAL SAFETY REQUIREMENT - YOU MUST FOLLOW THIS STRICTLY:
      
      User's Safety Preference: "#{safety_preference || 'Generally Safe'}"
      #{safety_context[:restriction_note]}
      
      YOU CAN ONLY RECOMMEND DESTINATIONS FROM THE FOLLOWING #{safety_context[:country_count]} COUNTRIES:
      #{safety_context[:country_list]}
      
      DO NOT recommend any country that is NOT in the above list. These countries have been pre-screened based on the 2025 Global Peace Index (GPI) to meet the user's safety requirements.
      
      Top countries by safety (for your reference):
       #{safety_context[:country_details]}
      
      The user selected "#{safety_preference}" which means they want destinations that are #{safety_context[:top_country]&.safety_description&.downcase || 'safe for travel'}.
      
      Return the response as a valid JSON object with a single key "destinations" that is an array where each object has the following keys:

      - "name": A creative name for this specific trip (e.g., "Costa Rican Jungle Adventure").
      - "destination_city": The primary city or location name for this destination. For better accuracy, include the state/province for cities in large countries (e.g., "Burlington, Vermont" or "Burlington, Wisconsin" for USA; "Paris, Texas" or just "Paris" for France). This should be a real, geocodable location name, NOT a creative name.
      - "destination_country": The country of the recommended destination. MUST be from the allowed country list above.
      - "description": A one-paragraph summary of the trip, mentioning why it's perfect for #{date_range}.
      - "details": Additional trip details, notes, or tips. Include seasonal information for the travel dates.
      - "itinerary": A detailed, day-by-day travel itinerary for EXACTLY #{length_of_stay} days. Create keys "Day 1", "Day 2", up to "Day #{length_of_stay}". Each day should have a detailed paragraph describing specific activities, sights, and dining suggestions appropriate for the travel dates.
      - "budget_min": Minimum trip cost (number). MUST be between $#{@preferences[:budget_min]} and $#{@preferences[:budget_max]}.
      - "budget_max": Maximum trip cost (number). MUST be between $#{@preferences[:budget_min]} and $#{@preferences[:budget_max]}.
      - "budget_breakdown": A JSON object with keys: "flights", "hotel", "food", "activities", "car_rental". The sum should roughly equal budget_max. Use 0 if not applicable.
      - "safety_score": The actual GPI safety score for this country (you can reference the list above for accurate scores).
      - "travel_style": Primary travel style matching "#{@preferences[:travel_style]}".
      - "visa_info": Visa requirements for citizens from #{@preferences[:passport_country]}.
      - "length_of_stay": Must be exactly #{length_of_stay} (as a number).
      - "travel_month": "#{travel_month}".
      - "trip_scope": Must be "#{@preferences[:trip_scope]}".
      - "trip_type": Must be "#{@preferences[:trip_type]}".
      - "general_purpose": "#{@preferences[:general_purpose]}"

      User Preferences Summary:
      - Trip Name Idea: #{@preferences[:name]}
      - Passport Country: #{@preferences[:passport_country]}
      - Budget Range: $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]}
      - Travel Dates: #{date_range}
      - Length of Stay: #{length_of_stay} days
      - Trip Type: #{@preferences[:trip_type]}
      - Travel Style: #{@preferences[:travel_style]}
      - Purpose: #{@preferences[:general_purpose]}
      - Safety Requirement: #{safety_preference} (only from pre-approved country list)
      - Scope: #{@preferences[:trip_scope]}

      IMPORTANT: 
      - The itinerary MUST have exactly #{length_of_stay} days
      - All destinations MUST be suitable for travel #{date_range}
      - Consider any holidays, festivals, or special events during this time period
      - Budget estimates MUST fall within $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]}
      - Only suggest #{@preferences[:trip_scope]} destinations
      - ONLY recommend countries from the provided safety-approved list above
      
      Return ONLY the JSON object, with no other text before or after it.
    PROMPT
  end

  def parse_response(response)
    raw_content = response.choices.first&.message&.content
    
    Rails.logger.info "=== Parsing OpenAI Response ==="
    Rails.logger.info "Raw content present: #{raw_content.present?}"
    Rails.logger.info "Raw content length: #{raw_content&.length}"
    Rails.logger.info "Raw content (first 500 chars): #{raw_content&.slice(0, 500)}"
    
    return [] unless raw_content

    begin
      # The AI is prompted to return a JSON with a "destinations" key.
      # We parse it and return the array inside that key.
      parsed_json = JSON.parse(raw_content, symbolize_names: true)
      destinations = parsed_json[:destinations] || []
      
      Rails.logger.info "=== Parsed JSON Successfully ==="
      Rails.logger.info "Number of destinations: #{destinations.length}"
      
      # Ensure all required fields are present with defaults if missing
      destinations.map do |dest|
        {
          name: dest[:name] || "Unnamed Trip",
          destination_city: dest[:destination_city] || dest[:name], # Use city if provided, fallback to name
          destination_country: dest[:destination_country] || "Unknown",
          description: dest[:description] || "",
          details: dest[:details] || "",
          itinerary: dest[:itinerary] || {},
          budget_min: dest[:budget_min]&.to_i || 0,
          budget_max: dest[:budget_max]&.to_i || 0,
          budget_breakdown: dest[:budget_breakdown] || {},
          safety_level: dest[:safety_level] || "level_1",
          travel_style: dest[:travel_style] || @preferences[:travel_style],
          visa_info: dest[:visa_info] || "Check visa requirements",
          length_of_stay: dest[:length_of_stay]&.to_i || @preferences[:length_of_stay]&.to_i,
          travel_month: dest[:travel_month] || @preferences[:travel_month],
          trip_scope: dest[:trip_scope] || @preferences[:trip_scope],
          trip_type: dest[:trip_type] || @preferences[:trip_type],
          general_purpose: dest[:general_purpose] || @preferences[:general_purpose],
          start_date: @preferences[:start_date],
          end_date: @preferences[:end_date]
        }
      end
    rescue JSON::ParserError => e
      Rails.logger.error "=== JSON Parse Error ==="
      Rails.logger.error "Error: #{e.message}"
      Rails.logger.error "Raw content: #{raw_content}"
      
      # Return an error object that can be displayed in the view
      [{
         name: "Error Generating Recommendations",
         destination_country: "Error",
         description: "There was an issue parsing the response from the AI. It may have returned an invalid format. Please try adjusting your preferences and submit again.",
         details: "Technical details: #{e.message}. Please try again.",
         itinerary: {},
         budget_min: 0,
         budget_max: 0,
         budget_breakdown: {},
         safety_level: "level_1",
         travel_style: "N/A",
         visa_info: "N/A",
         length_of_stay: @preferences[:length_of_stay]&.to_i || 4,
         travel_month: @preferences[:travel_month] || "Unknown",
         trip_scope: @preferences[:trip_scope] || "Unknown",
         trip_type: @preferences[:trip_type] || "Unknown",
         general_purpose: @preferences[:general_purpose] || "Unknown",
         start_date: @preferences[:start_date],
         end_date: @preferences[:end_date]
       }]
    end
  end
end
