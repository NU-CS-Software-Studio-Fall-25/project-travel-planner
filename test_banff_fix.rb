#!/usr/bin/env ruby
# Quick test to verify Banff search works

require_relative 'config/environment'

puts "Testing TripAdvisor service for Banff, Alberta, Canada"
puts "="*80

service = TripadvisorService.new
result = service.get_location_photos("Banff, Alberta", "Canada", 7)

puts "\nResult:"
puts "Success: #{result[:success]}"
puts "Location ID: #{result[:location_id]}"
puts "Location Name: #{result[:location_name]}"
puts "Description: #{result[:description]&.[](0, 200)}..."
puts "Photos Count: #{result[:photos]&.length || 0}"

if result[:photos]&.any?
  puts "\nFirst 3 photos:"
  result[:photos].take(3).each_with_index do |photo, i|
    puts "  #{i+1}. #{photo[:caption]}"
    puts "     URL: #{photo[:url]}"
  end
else
  puts "\n❌ No photos found!"
end

puts "\n" + "="*80
puts result[:success] ? "✅ SUCCESS!" : "❌ FAILED"
