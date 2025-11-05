# Test TripAdvisor API
# Run with: rails runner scripts/test_tripadvisor.rb

puts "="*60
puts "Testing TripAdvisor API"
puts "="*60

api_key = ENV['TRIPADVISOR_API_KEY']
puts "\n✓ API Key loaded: #{api_key[0..10]}...#{api_key[-5..-1]}" if api_key

service = TripadvisorService.new
result = service.get_location_photos('Miami, Florida', 'United States', 7)

puts "\nResult:"
puts "Success: #{result[:success]}"
puts "Location: #{result[:location_name]}"
puts "Photos found: #{result[:photos]&.count || 0}"
puts "Web URL: #{result[:web_url]}"

if result[:photos]&.any?
  puts "\nFirst photo:"
  puts "  Caption: #{result[:photos].first[:caption]}"
  puts "  URL: #{result[:photos].first[:url]}"
else
  puts "\n❌ No photos retrieved"
  puts "This likely means the API key restrictions are blocking the request."
  puts "\nPlease check your TripAdvisor API settings:"
  puts "1. Make sure restrictions are set to: IP addresses"
  puts "2. Add: 127.0.0.1/32"
  puts "3. Save and wait 1-2 minutes for changes to take effect"
  puts "4. Run this test again"
end

puts "\n" + "="*60
