# app/Services/openai_service.rb
require 'openai'

class OpenaiService
  def initialize(preferences)
    @client = OpenAI::Client.new(api_key: ENV.fetch('OPENAI_API_KEY'))
    @preferences = preferences
  end

  def get_recommendations
    prompt = build_prompt

    response = @client.chat.completions.create(
      model: "gpt-4o",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.7,
      max_tokens: 7000,
      response_format: { type: "json_object" }
    )

    # Parse the response and return it
    parse_response(response)
  end

  private

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
    
    # Convert safety levels to human-readable format and numeric equivalents
    safety_levels = @preferences[:safety_levels] || []
    safety_levels = safety_levels.reject(&:blank?) # Remove empty values
    
    safety_descriptions = {
      'level_1' => 'Level 1 - Safe Destinations (Exercise normal precautions)',
      'level_2' => 'Level 2 - Moderate Caution (Exercise increased caution)',
      'level_3' => 'Level 3 - High Risk (Reconsider travel)',
      'level_4' => 'Level 4 - Extreme Risk (Do not travel, Adventure only)'
    }
    
    acceptable_safety_text = safety_levels.map { |level| safety_descriptions[level] }.join(', ')
    
    # Get the most permissive level selected (lowest number = most restrictive)
    most_permissive_level = if safety_levels.include?('level_4')
                              'level_4'
                            elsif safety_levels.include?('level_3')
                              'level_3'
                            elsif safety_levels.include?('level_2')
                              'level_2'
                            else
                              'level_1'
                            end
    
    <<~PROMPT
      You are a professional travel planner. Based on the following travel preferences, suggest 5 travel destinations that STRICTLY match ALL the user's requirements.

      ⚠️ MOST IMPORTANT - USER'S SPECIFIC REQUIREMENTS:
      "#{@preferences[:general_purpose]}"
      
      READ THE ABOVE CAREFULLY! If the user mentions specific countries, cities, regions, or activities, you MUST prioritize those in your recommendations. This is the user's PRIMARY requirement and takes precedence over everything else.

      CRITICAL REQUIREMENTS - ALL recommendations MUST:
      1. Have itineraries for EXACTLY #{length_of_stay} days (no more, no less)
      2. Be suitable for travel #{date_range} (consider weather, seasonal events, holidays, and typical conditions for this specific time period)
      3. Fit within the budget range of $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]} (budget_min and budget_max MUST be within this range)
      4. Match the #{@preferences[:trip_scope]} scope (only suggest #{@preferences[:trip_scope]} destinations)
      5. Be appropriate for #{@preferences[:trip_type]} travelers
      6. Follow the #{@preferences[:travel_style]} travel style
      7. Have a safety level from the acceptable levels: #{acceptable_safety_text}
      8. Consider that the traveler is departing from: #{@preferences[:current_location]}
      9. MOST IMPORTANTLY: Address the user's specific purpose/requirements mentioned above
      
      SAFETY LEVEL DEFINITIONS:
      - "level_1" = Safe Destinations - Exercise normal precautions (most countries, popular tourist destinations)
      - "level_2" = Moderate Caution - Exercise increased caution (some political instability or crime concerns)
      - "level_3" = High Risk - Reconsider travel (significant safety concerns, ongoing conflicts)
      - "level_4" = Extreme Risk - Do not travel (active war zones, extreme danger, for Adventure travelers only)
      
      Return the response as a valid JSON object with a single key "destinations" that is an array where each object has the following keys:

      - "name": A creative name for this specific trip (e.g., "Costa Rican Jungle Adventure").
      - "destination_country": The country of the recommended destination.
      - "description": A one-paragraph summary of the trip, mentioning why it's perfect for #{date_range} and how it matches the user's purpose: "#{@preferences[:general_purpose]}".
      - "details": Additional trip details, notes, or tips. Include seasonal information for the travel dates. Mention how this destination aligns with the user's stated purpose.
      - "itinerary": A detailed, day-by-day travel itinerary for EXACTLY #{length_of_stay} days. Create keys "Day 1", "Day 2", up to "Day #{length_of_stay}". Each day should have a detailed paragraph describing specific activities, sights, and dining suggestions appropriate for the travel dates.
      - "budget_min": Minimum trip cost (number). MUST be between $#{@preferences[:budget_min]} and $#{@preferences[:budget_max]}.
      - "budget_max": Maximum trip cost (number). MUST be between $#{@preferences[:budget_min]} and $#{@preferences[:budget_max]}.
      - "budget_breakdown": A JSON object with keys: "flights", "hotel", "food", "activities", "car_rental". The sum should roughly equal budget_max. Use 0 if not applicable. Consider the departure location (#{@preferences[:current_location]}) when estimating flight costs.
      - "safety_level": The safety level of this destination. MUST be one of: "level_1", "level_2", "level_3", or "level_4". Choose from the acceptable levels: #{acceptable_safety_text}
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
      - Current Location (Departing From): #{@preferences[:current_location]}
      - Budget Range: $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]}
      - Travel Dates: #{date_range}
      - Length of Stay: #{length_of_stay} days
      - Trip Type: #{@preferences[:trip_type]}
      - Travel Style: #{@preferences[:travel_style]}
      - Acceptable Safety Levels: #{acceptable_safety_text}
      - Scope: #{@preferences[:trip_scope]}
      - USER'S MAIN PURPOSE/REQUIREMENTS: "#{@preferences[:general_purpose]}" ← THIS IS THE MOST IMPORTANT!

      IMPORTANT: 
      - The itinerary MUST have exactly #{length_of_stay} days
      - All destinations MUST be suitable for travel #{date_range}
      - Consider any holidays, festivals, or special events during this time period
      - Budget estimates MUST fall within $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]}
      - Only suggest #{@preferences[:trip_scope]} destinations
      - Safety level must be one of the acceptable levels (#{safety_levels.join(', ')})
      - Flight costs should reflect the distance from #{@preferences[:current_location]}
      - CRITICALLY IMPORTANT: Pay special attention to the user's stated purpose and any specific countries/regions/activities mentioned
      
      Return ONLY the JSON object, with no other text before or after it.
    PROMPT
  end

  def parse_response(response)
    raw_content = response.choices.first&.message&.content
    return [] unless raw_content

    begin
      # The AI is prompted to return a JSON with a "destinations" key.
      # We parse it and return the array inside that key.
      parsed_json = JSON.parse(raw_content, symbolize_names: true)
      destinations = parsed_json[:destinations] || []
      
      # Ensure all required fields are present with defaults if missing
      destinations.map do |dest|
        {
          name: dest[:name] || "Unnamed Trip",
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
