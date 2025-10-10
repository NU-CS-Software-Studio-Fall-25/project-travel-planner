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
    # This prompt instructs the AI to return a JSON object with a "destinations" key containing an array of 5 destinations
    # with a detailed structure including a full itinerary and budget breakdown.
    <<~PROMPT
      Based on the following travel preferences, suggest 5 travel destinations.
      Return the response as a valid JSON object with a single key "destinations" that is an array where each object has the following keys: "name", "destination_country", "description", "details", "itinerary", "budget_min", "budget_max", "budget_breakdown", "safety_score", "travel_style", "visa_info".

      - "name": A creative name for this specific trip (e.g., "Costa Rican Jungle Adventure").
      - "destination_country": The country of the recommended destination.
      - "description": A one-paragraph summary of the trip.
      - "details": Additional trip details, notes, or tips.
      - "itinerary": A very detailed, day-by-day travel itinerary for the user's specified 'length_of_stay'. For each day, provide a detailed, single-paragraph description of specific activities, sights, and dining suggestions. This should be a JSON object where keys are "Day 1", "Day 2", etc.
      - "budget_min": An estimated minimum cost for this trip, as a number. The budget range should be narrow and realistic.
      - "budget_max": An estimated maximum cost for this trip, as a number. The budget range should be narrow and realistic.
      - "budget_breakdown": A JSON object detailing the estimated costs. It must include keys for "flights", "hotel", "food", "activities", and "car_rental" (use 0 if not applicable).
      - "safety_score": An estimated safety score for the destination on a scale of 1-10.
      - "travel_style": The primary travel style for this trip (e.g., Adventure, Leisure, Luxury).
      - "visa_info": A brief note on whether a visa is likely required for a citizen from the user's passport country.

      User Preferences:
      - Trip Name Idea: #{@preferences[:name]}
      - Passport Country: #{@preferences[:passport_country]}
      - Budget: $#{@preferences[:budget_min]} - $#{@preferences[:budget_max]}
      - Desired Travel Month: #{@preferences[:travel_month]}
      - Length of Stay: #{@preferences[:length_of_stay]} days
      - Trip Type: #{@preferences[:trip_type]}
      - Travel Style: #{@preferences[:travel_style]}
      - Purpose: #{@preferences[:general_purpose]}
      - Safety Preference (1-10): #{@preferences[:safety_preference]}
      - Scope: #{@preferences[:trip_scope]}

      Ensure the entire response is only the JSON object, with no other text before or after it.
    PROMPT
  end

  def parse_response(response)
    raw_content = response.choices.first&.message&.content
    return [] unless raw_content

    begin
      # The AI is prompted to return a JSON with a "destinations" key.
      # We parse it and return the array inside that key.
      parsed_json = JSON.parse(raw_content, symbolize_names: true)
      parsed_json[:destinations] || []
    rescue JSON::ParserError => e
      # Return an error object that can be displayed in the view
      [{
         name: "Error Generating Recommendations",
         description: "There was an issue parsing the response from the AI. It may have returned an invalid format. Please try adjusting your preferences and submit again.",
         details: "Raw content: #{raw_content}",
         itinerary: "No itinerary could be generated.",
         budget_min: 0,
         budget_max: 0,
         safety_score: 0,
         travel_style: "N/A",
         visa_info: "N/A",
         destination_country: "Error"
       }]
    end
  end
end
