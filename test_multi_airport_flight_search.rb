#!/usr/bin/env ruby
# Test script for multi-airport flight search

require_relative 'config/environment'

puts "Testing Multi-Airport Flight Search"
puts "=" * 70

# Test preferences
preferences = {
  current_location: "Chicago, Illinois, United States",
  start_date: "2025-12-15",
  end_date: "2025-12-22",
  number_of_travelers: 1,
  max_budget: 3000
}

service = SerpapiFlightService.new(preferences)

# Test cities with multiple airports
test_cases = [
  { city: "New York", country: "United States", expected_airports: ["LGA", "JFK", "JRB", "JRA"] },
  { city: "London", country: "United Kingdom", expected_airports: ["LTN", "LGW", "LCY", "LHR", "STN"] },
  { city: "Tokyo", country: "Japan", expected_airports: ["NRT", "HND"] },
  { city: "Paris", country: "France", expected_airports: ["LBG", "CDG", "ORY"] }
]

test_cases.each do |test_case|
  puts "\n" + "-" * 70
  puts "Testing: #{test_case[:city]}, #{test_case[:country]}"
  puts "Expected airports: #{test_case[:expected_airports].join(', ')}"
  puts "-" * 70
  
  result = service.get_flight_price(test_case[:city], test_case[:country])
  
  if result[:success]
    puts "✓ SUCCESS"
    puts "  Best Price: $#{result[:price]}"
    puts "  Best Airport: #{result[:details][:arrival_airport]}"
    puts "  Airline: #{result[:details][:airline]}"
    puts "  Duration: #{result[:details][:duration]}"
    puts "  Stops: #{result[:details][:stops]}"
  else
    puts "✗ FAILED"
    puts "  Error: #{result[:error]}"
    if result[:details] && result[:details][:airports_checked]
      puts "  Airports checked: #{result[:details][:airports_checked].join(', ')}"
      if result[:details][:errors]
        puts "  Errors:"
        result[:details][:errors].each do |err|
          puts "    - #{err[:airport]}: #{err[:error]}"
        end
      end
    end
  end
end

puts "\n" + "=" * 70
puts "Test complete!"
puts "\nNote: This test requires a valid SerpAPI key and makes real API calls."
puts "Some tests may fail due to API limits or no available flights."
