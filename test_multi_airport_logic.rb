#!/usr/bin/env ruby
# Quick test to verify multi-airport logic without making API calls

require_relative 'config/environment'

puts "Testing Multi-Airport Selection Logic"
puts "=" * 60

# Create service
preferences = {
  current_location: "Chicago, Illinois, United States",
  start_date: "2025-12-15",
  end_date: "2025-12-22",
  number_of_travelers: 1
}

service = AirportLookupService.new

# Test cases
test_cases = [
  "New York, United States",
  "London, United Kingdom",
  "Tokyo, Japan",
  "Paris, France",
  "Los Angeles, United States",
  "Sydney, Australia"
]

test_cases.each do |location|
  puts "\nLocation: #{location}"
  airports = service.find_airports(location)

  if airports.any?
    puts "  ✓ Found #{airports.length} airport(s): #{airports.take(3).join(', ')}"
    if airports.length > 3
      puts "    (#{airports.length - 3} more available)"
    end
    puts "  → Will check: #{airports.take(3).join(', ')}"
  else
    puts "  ✗ No airports found"
  end
end

puts "\n" + "=" * 60
puts "Logic test complete!"
puts "\nThe service will now check up to 3 airports per city"
puts "and return the cheapest flight option."
