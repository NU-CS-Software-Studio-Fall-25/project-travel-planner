# app/Services/openai_service.rb

class OpenaiService
  def initialize(preferences)
    @client = OpenAI::Client.new(api_key: ENV.fetch('OPENAI_API_KEY'))
    @preferences = preferences
  end

  def get_recommendations
    prompt = build_prompt
    Rails.logger.info prompt

    begin
      Rails.logger.info "=== OpenAI API Call Starting ==="
      Rails.logger.info "API Key present: #{ENV['OPENAI_API_KEY'].present?}"
      Rails.logger.info "API Key length: #{ENV['OPENAI_API_KEY']&.length}"

      response = @client.chat.completions.create(
        model: "gpt-4o",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_tokens: 5000,
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
        number_of_travelers: @preferences[:number_of_travelers]&.to_i || 1,
        general_purpose: @preferences[:general_purpose] || "Unknown",
        start_date: @preferences[:start_date],
        end_date: @preferences[:end_date]
      }]
    end
  end

  private

  # Determine the user's current country for domestic travel
  # Parses country from current_location (expected from Google Maps API)
  # Falls back to passport_country if parsing fails
  def get_current_country
    current_location = @preferences[:current_location].to_s.strip
    
    if current_location.present?
      # Google Maps typically formats addresses as: "City, State/Province, Country"
      # Examples: "Chicago, IL, USA", "Toronto, ON, Canada", "London, UK", "Paris, France"
      
      parts = current_location.split(',').map(&:strip)
      
      # If there are 3 or more parts, the last part is usually the country
      if parts.length >= 3
        country = parts.last
        # Normalize common country name variations
        country_mapping = {
          "USA" => "United States",
          "US" => "United States",
          "U.S." => "United States",
          "U.S.A." => "United States",
          "UK" => "United Kingdom",
          "U.K." => "United Kingdom"
        }
        country = country_mapping[country] || country
        Rails.logger.info "Detected country from current_location: #{country} (from: #{current_location})"
        return country
      elsif parts.length == 2
        # Format might be "City, Country" (e.g., "Paris, France", "London, England")
        potential_country = parts.last
        # Check if it looks like a country (not a state abbreviation)
        if potential_country.length > 2 || ["UK", "US"].include?(potential_country)
          country_mapping = {
            "USA" => "United States",
            "US" => "United States",
            "UK" => "United Kingdom",
            "England" => "United Kingdom",
            "Scotland" => "United Kingdom",
            "Wales" => "United Kingdom",
            "Northern Ireland" => "United Kingdom"
          }
          country = country_mapping[potential_country] || potential_country
          Rails.logger.info "Detected country from current_location (2-part): #{country} (from: #{current_location})"
          return country
        end
      end
      
      # Fallback: Check for US states in the location string (in case format is different)
      us_states = ["Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", 
                   "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa",
                   "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan",
                   "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
                   "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio",
                   "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota",
                   "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia",
                   "Wisconsin", "Wyoming", "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
                   "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS",
                   "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA",
                   "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
      
      if us_states.any? { |state| current_location.include?(state) }
        Rails.logger.info "Detected USA from current_location (state found): #{current_location}"
        return "United States"
      end
      
      # Check for Canadian provinces
      canadian_provinces = ["Alberta", "British Columbia", "Manitoba", "New Brunswick", 
                           "Newfoundland and Labrador", "Nova Scotia", "Ontario", "Prince Edward Island",
                           "Quebec", "Saskatchewan", "AB", "BC", "MB", "NB", "NL", "NS", "ON", "PE", "QC", "SK"]
      
      if canadian_provinces.any? { |province| current_location.include?(province) }
        Rails.logger.info "Detected Canada from current_location (province found): #{current_location}"
        return "Canada"
      end
    end
    
    # Fallback to passport_country if we can't determine from current_location
    Rails.logger.info "Could not parse country from current_location '#{current_location}', using passport_country: #{@preferences[:passport_country]}"
    @preferences[:passport_country]
  end

  # Get eligible countries based on user's safety preference from GPI database
  def get_safe_countries(safety_preference)
    return CountrySafetyScore.all if safety_preference.blank?

    countries = CountrySafetyScore.for_safety_level(safety_preference)

    # Filter by trip scope if needed
    if @preferences[:trip_scope] == "Domestic"
      # For domestic trips, use the country inferred from current_location
      # (domestic = within the country they're currently in)
      current_country = get_current_country
      
      if current_country.present?
        # For domestic trips, check if current country meets safety criteria
        country_record = CountrySafetyScore.find_by(country_name: current_country, year: 2025)

        if country_record && countries.exists?(country_name: current_country)
          # Current country meets the safety criteria
          countries = countries.where(country_name: current_country)
        elsif country_record
          # Current country exists but doesn't meet safety criteria - include it anyway for domestic trips
          # but note the actual safety level
          Rails.logger.warn "Domestic trip: Including #{current_country} (GPI: #{country_record.gpi_score}, #{country_record.safety_level}) even though it doesn't meet '#{safety_preference}' criteria"
          countries = CountrySafetyScore.where(country_name: current_country)
        else
          # Current country not in database - return empty to trigger appropriate message
          countries = CountrySafetyScore.none
        end
      else
        countries = CountrySafetyScore.none
      end
    elsif @preferences[:trip_scope] == "International"
      # For international trips, exclude the country they're currently in
      current_country = get_current_country
      if current_country.present?
        countries = countries.where.not(country_name: current_country)
      end
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
    You are a professional travel planner. Based on the following travel preferences, suggest one travel destinations that STRICTLY match ALL the user's requirements.
  
    CRITICAL REQUIREMENTS - ALL recommendations MUST:
    1. Have itineraries for EXACTLY #{length_of_stay} days (no more, no less)
    2. Be suitable for travel #{date_range} (consider weather, seasonal events, holidays, and typical conditions for this specific time period)
    3. Fit within the budget range of $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]} (budget_min and budget_max MUST be within this range)
    4. Match the #{@preferences[:trip_scope]} scope (only suggest #{@preferences[:trip_scope]} destinations)
    5. Be appropriate for #{@preferences[:number_of_travelers] || 1} travelers (budget calculations MUST account for this number of people)
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
    - "itinerary": A detailed, day-by-day travel itinerary for EXACTLY #{length_of_stay} days. 
       • Create keys "Day 1", "Day 2", up to "Day #{length_of_stay}".  
       • Each day MUST include **exactly one full paragraph (no lists)**.  
       • Each paragraph MUST contain **at least 6 complete sentences**, each describing **distinct morning, afternoon, evening, and cultural/dining activities**, ensuring detail equivalent to 100+ words.  
       • If any day's paragraph is under 6 sentences, the output will be rejected.  
       • Focus on realism and storytelling — the itinerary should read like a high-quality travel magazine description, not a summary.
  
    - "budget_min": Minimum trip cost (number). MUST be between $#{@preferences[:budget_min]} and $#{@preferences[:budget_max]}.
    - "budget_max": Maximum trip cost (number). MUST be between $#{@preferences[:budget_min]} and $#{@preferences[:budget_max]}.
    - "budget_breakdown": A JSON object with these detailed keys (ALL COSTS MUST BE TOTAL FOR #{@preferences[:number_of_travelers] || 1} TRAVELERS):
          {
            "flights": {
                "description": "Round-trip flight details including exact route (from #{@preferences[:passport_country]}'s major airport, e.g., JFK or LAX, to destination airport, e.g., CDG Paris or OSL Oslo) × #{@preferences[:number_of_travelers] || 1} travelers",
                "cost_per_person": <numeric value>,
                "total_cost": <numeric value for all #{@preferences[:number_of_travelers] || 1} travelers>
            },
            "hotel": {
                "description": "Hotel name or type (e.g., 4-star boutique, beachfront resort) and nightly rate with total for #{length_of_stay} nights for #{@preferences[:number_of_travelers] || 1} travelers",
                "cost_per_night": <numeric value for accommodating all #{@preferences[:number_of_travelers] || 1} travelers>,
                "total_cost": <numeric value for all #{@preferences[:number_of_travelers] || 1} travelers for entire stay>
            },
            "food": {
                "description": "Average per-day cost of meals and drinks with local cuisine examples for #{@preferences[:number_of_travelers] || 1} travelers",
                "cost_per_day_per_person": <numeric value>,
                "cost_per_day_total": <numeric value for all #{@preferences[:number_of_travelers] || 1} travelers>,
                "total_cost": <numeric value for all #{@preferences[:number_of_travelers] || 1} travelers for entire trip>
            },
            "activities": {
                "description": "List each major paid activity (e.g., guided tour, museum ticket, adventure excursion) with individual cost per person and total for #{@preferences[:number_of_travelers] || 1} travelers",
                "total_cost": <numeric value for all #{@preferences[:number_of_travelers] || 1} travelers>
            },
            "car_rental": {
                "description": "Vehicle type (e.g., compact, SUV, minivan based on #{@preferences[:number_of_travelers] || 1} travelers) and total rental cost for duration of stay",
                "total_cost": <numeric value>
            },
            "total_trip_cost": "Sum of all above categories for ALL #{@preferences[:number_of_travelers] || 1} travelers; must match budget_max approximately"
          }
  
    - "safety_score": The actual GPI safety score for this country (you can reference the list above for accurate scores).
    - "travel_style": Primary travel style matching "#{@preferences[:travel_style]}".  
    - "visa_info": Visa requirements for citizens from #{@preferences[:passport_country]}.  
    - "length_of_stay": Must be exactly #{length_of_stay} (as a number).  
    - "travel_month": "#{travel_month}".  
    - "trip_scope": Must be "#{@preferences[:trip_scope]}".  
    - "number_of_travelers": Must be #{@preferences[:number_of_travelers] || 1} (as a number).  
    - "general_purpose": "#{@preferences[:general_purpose]}"
  
    User Preferences Summary:
    - Trip Name Idea: #{@preferences[:name]}
    - Passport Country: #{@preferences[:passport_country]}
    - Budget Range: $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]} (TOTAL for all #{@preferences[:number_of_travelers] || 1} travelers)
    - Travel Dates: #{date_range}
    - Length of Stay: #{length_of_stay} days
    - Number of Travelers: #{@preferences[:number_of_travelers] || 1} people
    - Travel Style: #{@preferences[:travel_style]}
    - Purpose: #{@preferences[:general_purpose]}
    - Safety Requirement: #{safety_preference} (only from pre-approved country list)
    - Scope: #{@preferences[:trip_scope]}
  
    IMPORTANT:
    - The itinerary MUST have exactly #{length_of_stay} days
    - Each day MUST have exactly ONE detailed paragraph of at least 6 complete sentences (no bullet points or short entries)
    - Each day's text should be approximately 100+ words
    - The budget_breakdown MUST include realistic flight routes, nightly hotel costs, per-day food costs, detailed activity costs, rental car info, and a total_trip_cost line.
    - ALL BUDGET CALCULATIONS MUST BE FOR #{@preferences[:number_of_travelers] || 1} TRAVELERS (multiply per-person costs accordingly)
    - Hotel costs should reflect appropriate room configuration for #{@preferences[:number_of_travelers] || 1} travelers (e.g., single room, double room, family suite, multiple rooms)
    - All destinations MUST be suitable for travel #{date_range}
    - Consider any holidays, festivals, or special events during this time period
    - Budget estimates MUST fall within $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]} (TOTAL for all #{@preferences[:number_of_travelers] || 1} travelers)
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
          number_of_travelers: dest[:number_of_travelers]&.to_i || @preferences[:number_of_travelers]&.to_i || 1,
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
         number_of_travelers: @preferences[:number_of_travelers]&.to_i || 1,
         general_purpose: @preferences[:general_purpose] || "Unknown",
         start_date: @preferences[:start_date],
         end_date: @preferences[:end_date]
       }]
    end
  end
end
