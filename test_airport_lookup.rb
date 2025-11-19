#!/usr/bin/env ruby
# Test script for AirportLookupService

require_relative 'config/environment'

puts "Testing AirportLookupService with comprehensive airport data"
puts "=" * 60

service = AirportLookupService.new

# Test cases from the error message
test_cases = [
  "Queenstown, New Zealand",
  "Reykjavik, Iceland",
  "Kyoto, Japan",
  "New York, United States",
  "London, United Kingdom",
  "Sydney, Australia",
  "Paris, France",
  "Tokyo, Japan",
  "Osaka, Japan",
  "Auckland, New Zealand",
  "Singapore, Singapore",
  "Bangkok, Thailand",
  "Mumbai, India",
  "Dubai, United Arab Emirates",
  "Istanbul, Turkey"
]

test_cases.each do |location|
  puts "\nTesting: #{location}"
  airports = service.find_airports(location)
  nearest = service.find_nearest_airport(location)
  
  if airports.any?
    puts "  ✓ Found airports: #{airports.join(', ')}"
    puts "  ✓ Nearest: #{nearest}"
  else
    puts "  ✗ No airports found"
  end
end

puts "\n" + "=" * 60
puts "Test complete!"
