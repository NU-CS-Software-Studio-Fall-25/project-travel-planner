# app/Services/openai_service.rb

class OpenaiService
  MAX_ITERATIONS = 3 # Maximum attempts to find an acceptable destination
  FLIGHT_BUDGET_THRESHOLD = 0.5 # Flight should not exceed 50% of max budget

  def initialize(preferences)
    @client = OpenAI::Client.new(api_key: ENV.fetch('OPENAI_API_KEY'))
    @preferences = preferences
    @serpapi_service = SerpapiFlightService.new(preferences)
    @rejected_cities = []
  end

  def get_recommendations
    Rails.logger.info "=== Starting Iterative Recommendation Process ==="
    
    # Iterate to find an acceptable destination
    MAX_ITERATIONS.times do |iteration|
      Rails.logger.info "=== Iteration #{iteration + 1}/#{MAX_ITERATIONS} ==="
      
      # Step 1: Get city recommendation from OpenAI
      city_result = get_city_recommendation
      
      if city_result[:error]
        Rails.logger.error "Failed to get city recommendation: #{city_result[:error]}"
        next
      end
      
      destination_city = city_result[:city]
      destination_country = city_result[:country]
      
      Rails.logger.info "OpenAI recommended: #{destination_city}, #{destination_country}"
      
      # Step 2: Check flight price with SerpAPI
      flight_result = @serpapi_service.get_flight_price(destination_city, destination_country)
      
      if !flight_result[:success]
        Rails.logger.warn "Flight search failed: #{flight_result[:error]}"
        @rejected_cities << {
          city: destination_city,
          country: destination_country,
          reason: "Flight search unavailable: #{flight_result[:error]}"
        }
        next
      end
      
      flight_price = flight_result[:price]
      max_budget = @preferences[:budget_max].to_f
      flight_budget_limit = max_budget * FLIGHT_BUDGET_THRESHOLD
      
      Rails.logger.info "Flight Price: $#{flight_price}, Budget Limit (50%): $#{flight_budget_limit}"
      
      # Step 3: Validate flight price
      if flight_price > flight_budget_limit
        Rails.logger.warn "Flight too expensive: $#{flight_price} > $#{flight_budget_limit}"
        @rejected_cities << {
          city: destination_city,
          country: destination_country,
          reason: "Flight cost $#{flight_price} exceeds 50% of budget ($#{flight_budget_limit})"
        }
        next
      end
      
      # Step 4: Flight is acceptable! Get full travel plan
      Rails.logger.info "✓ Acceptable destination found: #{destination_city}"
      
      full_plan = get_full_travel_plan(destination_city, destination_country, flight_result)
      
      if full_plan[:error]
        Rails.logger.error "Failed to get full plan: #{full_plan[:error]}"
        @rejected_cities << {
          city: destination_city,
          country: destination_country,
          reason: "Failed to generate travel plan: #{full_plan[:error]}"
        }
        next
      end
      
      return full_plan[:recommendations]
    end
    
    # If we get here, we failed to find an acceptable destination
    Rails.logger.error "=== Failed to find acceptable destination after #{MAX_ITERATIONS} attempts ==="
    
    return [{
      name: "No Suitable Destination Found",
      destination_country: "N/A",
      description: "We couldn't find a suitable travel destination within your budget after checking #{MAX_ITERATIONS} options.",
      details: build_rejection_summary,
      itinerary: {},
      budget_min: 0,
      budget_max: 0,
      budget_breakdown: {},
      safety_level: "level_1",
      travel_style: @preferences[:travel_style] || "N/A",
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

  private

  # Get city recommendation from OpenAI (first phase)
  def get_city_recommendation
    prompt = build_city_prompt
    
    begin
      Rails.logger.info "=== Requesting City Recommendation from OpenAI ==="
      
      response = @client.chat.completions.create(
        model: "gpt-4o",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_tokens: 500,
        response_format: { type: "json_object" }
      )
      
      raw_content = response.choices.first&.message&.content
      parsed = JSON.parse(raw_content, symbolize_names: true)
      
      {
        city: parsed[:city],
        country: parsed[:country]
      }
      
    rescue => e
      Rails.logger.error "Error getting city recommendation: #{e.message}"
      { error: e.message }
    end
  end

  # Get full travel plan from OpenAI (second phase - after flight validation)
  def get_full_travel_plan(destination_city, destination_country, flight_result)
    prompt = build_full_plan_prompt(destination_city, destination_country, flight_result)
    
    begin
      Rails.logger.info "=== Requesting Full Travel Plan from OpenAI ==="
      
      response = @client.chat.completions.create(
        model: "gpt-4o",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_tokens: 5000,
        response_format: { type: "json_object" }
      )
      
      parsed_recommendations = parse_response(response)
      
      # Inject actual flight price into the recommendations
      parsed_recommendations.each do |rec|
        if rec[:budget_breakdown].is_a?(Hash)
          # Ensure flight_result[:price] is a number
          flight_price = flight_result[:price].to_f
          travelers = (@preferences[:number_of_travelers] || 1).to_i
          
          rec[:budget_breakdown][:flights] = {
            description: "Round-trip flight from #{flight_result[:details][:departure_airport]} to #{flight_result[:details][:arrival_airport]} × #{travelers} travelers via #{flight_result[:details][:airline]}",
            cost_per_person: (flight_price / travelers).round(2),
            total_cost: flight_price.round(2),
            duration: flight_result[:details][:duration].to_s,
            stops: flight_result[:details][:stops].to_i
          }
        end
      end
      
      { recommendations: parsed_recommendations }
      
    rescue => e
      Rails.logger.error "Error getting full plan: #{e.message}"
      { error: e.message }
    end
  end

  # Build prompt for city recommendation only
  def build_city_prompt
    safety_context = build_safety_context(@preferences[:safety_preference])
    
    rejected_list = if @rejected_cities.empty?
                      "None yet"
                    else
                      @rejected_cities.map { |r| "#{r[:city]}, #{r[:country]} (#{r[:reason]})" }.join("\n")
                    end
    
    <<~PROMPT
      You are a professional travel planner. Based on the user's preferences, suggest ONE destination city that matches their requirements.
      
      CRITICAL SAFETY REQUIREMENT:
      User's Safety Preference: "#{@preferences[:safety_preference] || 'Generally Safe'}"
      
      YOU CAN ONLY RECOMMEND DESTINATIONS FROM THE FOLLOWING #{safety_context[:country_count]} COUNTRIES:
      #{safety_context[:country_list]}
      
      Previously Rejected Cities (DO NOT recommend these again):
      #{rejected_list}
      
      User Requirements:
      - Travel Dates: #{@preferences[:start_date]} to #{@preferences[:end_date]}
      - Budget: $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]} (TOTAL for #{@preferences[:number_of_travelers] || 1} travelers)
      - Trip Scope: #{@preferences[:trip_scope]}
      - Travel Style: #{@preferences[:travel_style]}
      - Purpose: #{@preferences[:general_purpose]}
      - From: #{@preferences[:current_location]} (#{@preferences[:passport_country]})
      
      Return ONLY a JSON object with:
      {
        "city": "City Name",
        "country": "Country Name"
      }
      
      The city must be in one of the allowed countries above, have reasonable flight connections, and match the user's preferences.
      DO NOT suggest any city from the rejected list.
    PROMPT
  end

  # Build prompt for full travel plan with known destination and flight price
  def build_full_plan_prompt(destination_city, destination_country, flight_result)
    start_date = @preferences[:start_date].present? ? Date.parse(@preferences[:start_date].to_s) : nil
    end_date = @preferences[:end_date].present? ? Date.parse(@preferences[:end_date].to_s) : nil
    length_of_stay = @preferences[:length_of_stay] ||
                     (start_date && end_date ? (end_date - start_date).to_i + 1 : 4)
    travel_month = @preferences[:travel_month] || (start_date ? start_date.strftime("%B") : "")
    
    date_range = if start_date && end_date
                   "#{start_date.strftime('%B %d, %Y')} to #{end_date.strftime('%B %d, %Y')}"
                 elsif travel_month.present?
                   "during #{travel_month}"
                 else
                   "within the next few months"
                 end
    
    flight_cost = flight_result[:price]
    remaining_budget_max = @preferences[:budget_max].to_f - flight_cost
    remaining_budget_min = [@preferences[:budget_min].to_f - flight_cost, 0].max
    
    <<~PROMPT
      You are a professional travel planner. Create a detailed travel plan for #{destination_city}, #{destination_country}.
      
      CONFIRMED FLIGHT INFORMATION:
      - Flight Cost: $#{flight_cost} (already booked/confirmed)
      - Route: #{flight_result[:details][:departure_airport]} to #{flight_result[:details][:arrival_airport]}
      - Airline: #{flight_result[:details][:airline]}
      
      REMAINING BUDGET for accommodation, food, activities, and transportation:
      - Minimum: $#{remaining_budget_min.round(2)}
      - Maximum: $#{remaining_budget_max.round(2)}
      
      User Preferences:
      - Travel Dates: #{date_range}
      - Length of Stay: #{length_of_stay} days
      - Number of Travelers: #{@preferences[:number_of_travelers] || 1} people
      - Travel Style: #{@preferences[:travel_style]}
      - Purpose: #{@preferences[:general_purpose]}
      
      Return a JSON object with a "destinations" key containing an array with ONE destination object:
      
      {
        "destinations": [{
          "name": "Creative trip name (e.g., '#{destination_city} Adventure')",
          "destination_city": "#{destination_city}",
          "destination_country": "#{destination_country}",
          "description": "One-paragraph summary of the trip",
          "details": "Additional tips and seasonal information",
          "itinerary": {
            "Day 1": "Detailed paragraph (6+ sentences, 100+ words) for day 1",
            "Day 2": "Detailed paragraph (6+ sentences, 100+ words) for day 2",
            ...
            "Day #{length_of_stay}": "Detailed paragraph (6+ sentences, 100+ words) for day #{length_of_stay}"
          },
          "budget_min": #{@preferences[:budget_min]},
          "budget_max": #{@preferences[:budget_max]},
          "budget_breakdown": {
            "hotel": {
              "description": "Hotel details for #{length_of_stay} nights",
              "cost_per_night": <number for all #{@preferences[:number_of_travelers] || 1} travelers>,
              "total_cost": <number>
            },
            "food": {
              "description": "Meals budget per day",
              "cost_per_day_per_person": <number>,
              "cost_per_day_total": <number for all travelers>,
              "total_cost": <number for entire trip>
            },
            "activities": {
              "description": "Main activities with costs",
              "total_cost": <number>
            },
            "car_rental": {
              "description": "Transportation details",
              "total_cost": <number>
            },
            "total_trip_cost": "Total of all categories (must equal budget_max)"
          },
          "travel_style": "#{@preferences[:travel_style]}",
          "visa_info": "Visa requirements for #{@preferences[:passport_country]} citizens",
          "length_of_stay": #{length_of_stay},
          "travel_month": "#{travel_month}",
          "trip_scope": "#{@preferences[:trip_scope]}",
          "number_of_travelers": #{@preferences[:number_of_travelers] || 1},
          "general_purpose": "#{@preferences[:general_purpose]}"
        }]
      }
      
      IMPORTANT:
      - Flight cost of $#{flight_cost} is already confirmed and will be added separately
      - Budget breakdown should focus on: hotel, food, activities, car_rental
      - Each itinerary day MUST be one detailed paragraph with 6+ sentences
      - Total costs must fit within remaining budget of $#{remaining_budget_min.round(2)} - $#{remaining_budget_max.round(2)}
    PROMPT
  end

  # Build summary of rejected cities for user feedback
  def build_rejection_summary
    return "No destinations checked yet." if @rejected_cities.empty?
    
    summary = "We checked the following destinations but they didn't meet your budget requirements:\n\n"
    
    @rejected_cities.each_with_index do |rejected, index|
      summary += "#{index + 1}. #{rejected[:city]}, #{rejected[:country]}\n"
      summary += "   Reason: #{rejected[:reason]}\n\n"
    end
    
    summary += "\nSuggestions:\n"
    summary += "- Try increasing your budget\n"
    summary += "- Consider different travel dates (off-peak seasons are cheaper)\n"
    summary += "- Look for destinations closer to your location\n"
    summary += "- Reduce the number of travelers\n"
    
    summary
  end

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
