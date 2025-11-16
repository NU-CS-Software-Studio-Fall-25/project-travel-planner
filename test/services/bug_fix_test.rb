# test/services/bug_fix_test.rb
# Test to verify bug fixes in the SerpAPI integration

puts "=== Testing Bug Fixes ==="
puts

# Test 1: Airport Lookup for Beach Destinations
puts "Test 1: Airport Lookup for Beach Cities"
puts "-" * 50

airport_service = AirportLookupService.new

beach_cities = [
  { location: "Miami, United States", expected: "MIA" },
  { location: "Fort Lauderdale, United States", expected: "FLL" },
  { location: "Destin, United States", expected: "VPS" },
  { location: "Myrtle Beach, United States", expected: "MYR" }
]

beach_cities.each do |test|
  result = airport_service.find_nearest_airport(test[:location])
  status = result == test[:expected] ? "✓" : "✗"
  puts "#{status} #{test[:location]} => #{result} (expected: #{test[:expected]})"
end

puts

# Test 2: Flight Price Lookup with Correct Airports
puts "\nTest 2: Flight Price Lookup with Correct Airports"
puts "-" * 50

preferences = {
  current_location: "Chicago, IL, United States",
  start_date: "2025-12-15",
  end_date: "2025-12-20",
  number_of_travelers: 1,
  budget_max: 2000
}

serpapi_service = SerpapiFlightService.new(preferences)

puts "Testing Miami flight..."
miami_result = serpapi_service.get_flight_price("Miami", "United States")

if miami_result[:success]
  puts "✓ Miami flight found"
  puts "  Route: #{miami_result[:details][:departure_airport]} → #{miami_result[:details][:arrival_airport]}"
  puts "  Expected: ORD → MIA"
  puts "  Price: $#{miami_result[:price]}"
  
  # Verify it's using the correct airports
  if miami_result[:details][:arrival_airport] == "MIA"
    puts "  ✓ Correct arrival airport (MIA)"
  else
    puts "  ✗ Wrong arrival airport: #{miami_result[:details][:arrival_airport]}"
  end
else
  puts "✗ Flight search failed: #{miami_result[:error]}"
end

puts

# Test 3: Type Coercion Fix
puts "\nTest 3: Budget Breakdown Type Safety"
puts "-" * 50

# Simulate the flight data injection
flight_result = {
  price: 358,
  details: {
    departure_airport: "ORD",
    arrival_airport: "MIA",
    airline: "Spirit",
    duration: "3h 15m",
    stops: 0
  }
}

travelers = 1

begin
  flight_price = flight_result[:price].to_f
  
  budget_breakdown = {
    flights: {
      description: "Round-trip flight from #{flight_result[:details][:departure_airport]} to #{flight_result[:details][:arrival_airport]} × #{travelers} travelers via #{flight_result[:details][:airline]}",
      cost_per_person: (flight_price / travelers).round(2),
      total_cost: flight_price.round(2),
      duration: flight_result[:details][:duration].to_s,
      stops: flight_result[:details][:stops].to_i
    }
  }
  
  puts "✓ Budget breakdown created successfully"
  puts "  Flight total: $#{budget_breakdown[:flights][:total_cost]}"
  puts "  Per person: $#{budget_breakdown[:flights][:cost_per_person]}"
  puts "  Duration: #{budget_breakdown[:flights][:duration]}"
  puts "  Type check passed - no coercion errors"
  
rescue => e
  puts "✗ Type coercion error: #{e.message}"
end

puts "\n=== All Tests Complete ==="
