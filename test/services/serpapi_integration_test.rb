# test/services/serpapi_integration_test.rb
#
# Quick manual test for the SerpAPI integration
# Run with: rails runner test/services/serpapi_integration_test.rb

puts "=== Testing SerpAPI Flight Integration ==="
puts

# Test 1: Airport Lookup Service
puts "Test 1: Airport Lookup Service"
puts "-" * 50
airport_service = AirportLookupService.new

test_locations = [
  "Chicago, IL, United States",
  "New York, NY, USA",
  "Paris, France",
  "Tokyo, Japan",
  "Sydney, Australia"
]

test_locations.each do |location|
  airports = airport_service.find_airports(location)
  primary = airport_service.find_nearest_airport(location)
  puts "Location: #{location}"
  puts "  Airports: #{airports.join(', ')}"
  puts "  Primary: #{primary}"
  puts
end

# Test 2: SerpAPI Flight Service
puts "\nTest 2: SerpAPI Flight Service"
puts "-" * 50

# Create mock preferences
preferences = {
  current_location: "Chicago, IL, United States",
  start_date: "2025-12-15",
  end_date: "2025-12-22",
  number_of_travelers: 2,
  budget_max: 5000
}

serpapi_service = SerpapiFlightService.new(preferences)

# Test flight price lookup
puts "Testing flight from Chicago to Paris..."
result = serpapi_service.get_flight_price("Paris", "France")

if result[:success]
  puts "✓ Flight search successful!"
  puts "  Price: $#{result[:price]}"
  puts "  From: #{result[:details][:departure_airport]}"
  puts "  To: #{result[:details][:arrival_airport]}"
  puts "  Airline: #{result[:details][:airline]}"
  puts "  Duration: #{result[:details][:duration]}"
  puts "  Stops: #{result[:details][:stops]}"
else
  puts "✗ Flight search failed: #{result[:error]}"
end

puts "\n=== Test Complete ==="
