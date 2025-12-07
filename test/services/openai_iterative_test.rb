# test/services/openai_iterative_test.rb
#
# Test the full iterative OpenAI + SerpAPI recommendation algorithm
# Run with: rails runner test/services/openai_iterative_test.rb

puts "=== Testing Iterative Recommendation Algorithm ==="
puts

# Create realistic test preferences
preferences = {
  name: "Test Trip",
  current_location: "Chicago, IL, United States",
  passport_country: "United States",
  start_date: "2025-12-15",
  end_date: "2025-12-22",
  length_of_stay: 8,
  travel_month: "December",
  budget_min: 2000,
  budget_max: 4000,  # Max budget $4000, so flights must be under $2000
  number_of_travelers: 2,
  trip_scope: "International",
  travel_style: "Relaxation",
  general_purpose: "Leisure",
  safety_preference: "Generally Safe"
}

puts "Test Preferences:"
puts "-" * 50
puts "From: #{preferences[:current_location]}"
puts "Dates: #{preferences[:start_date]} to #{preferences[:end_date]} (#{preferences[:length_of_stay]} days)"
puts "Budget: $#{preferences[:budget_min]} - $#{preferences[:budget_max]}"
puts "Travelers: #{preferences[:number_of_travelers]}"
puts "Scope: #{preferences[:trip_scope]}"
puts "Safety: #{preferences[:safety_preference]}"
puts

puts "Starting recommendation process..."
puts "(This will make OpenAI API calls and may take 30-60 seconds)"
puts

begin
  openai_service = OpenaiService.new(preferences)
  recommendations = openai_service.get_recommendations

  puts "\n=== Results ==="
  puts "-" * 50

  if recommendations.empty?
    puts "✗ No recommendations returned"
  else
    recommendations.each_with_index do |rec, i|
      puts "\nRecommendation #{i + 1}:"
      puts "  Name: #{rec[:name]}"
      puts "  Destination: #{rec[:destination_city]}, #{rec[:destination_country]}"
      puts "  Description: #{rec[:description][0..150]}..."

      if rec[:budget_breakdown].present? && rec[:budget_breakdown][:flights]
        puts "\n  Flight Details:"
        puts "    Cost: $#{rec[:budget_breakdown][:flights][:total_cost]}"
        puts "    Route: #{rec[:budget_breakdown][:flights][:description]}"
        puts "    Duration: #{rec[:budget_breakdown][:flights][:duration]}"
        puts "    Stops: #{rec[:budget_breakdown][:flights][:stops]}"
      end

      puts "\n  Budget:"
      puts "    Min: $#{rec[:budget_min]}"
      puts "    Max: $#{rec[:budget_max]}"

      if rec[:budget_breakdown][:total_trip_cost]
        puts "    Total: $#{rec[:budget_breakdown][:total_trip_cost]}"
      end

      puts "\n  Itinerary Days: #{rec[:itinerary]&.keys&.count || 0}"

      # Check if destination is a "No Suitable Destination Found" error
      if rec[:name].include?("No Suitable Destination") || rec[:name].include?("Error")
        puts "\n  ⚠️  Note: This is an error/fallback response"
        puts "  Details: #{rec[:details][0..200]}..."
      else
        puts "\n  ✓ Valid recommendation generated"
      end
    end
  end

  puts "\n=== Test Complete ==="

rescue => e
  puts "\n✗ Error during test:"
  puts "  #{e.class}: #{e.message}"
  puts "\n  Backtrace:"
  e.backtrace.first(5).each { |line| puts "    #{line}" }
end
