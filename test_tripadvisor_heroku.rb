# Test TripAdvisor API from Heroku
# Run this to test if the API works for a known location

require 'net/http'
require 'json'

API_KEY = ENV['TRIPADVISOR_API_KEY'] || 'BD9366999C904AA496AA71854FCD2EA5'
BASE_URL = 'https://api.content.tripadvisor.com/api/v1'

def test_location(city, country)
  puts "\n" + "="*60
  puts "Testing: #{city}, #{country}"
  puts "="*60

  # Search for location
  search_query = "#{city}, #{country}"
  uri = URI("#{BASE_URL}/location/search")
  uri.query = URI.encode_www_form({
    key: API_KEY,
    searchQuery: search_query,
    language: 'en'
  })

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri)
  request['Accept'] = 'application/json'
  request['Referer'] = 'https://travel-planner-cs397-9396d2cb2102.herokuapp.com'

  puts "Request URL: #{uri}"
  puts "Referer: #{request['Referer']}"

  response = http.request(request)

  puts "Response Code: #{response.code}"

  if response.code == '200'
    data = JSON.parse(response.body)
    if data['data'] && data['data'].any?
      puts "✅ SUCCESS! Found #{data['data'].length} results"
      data['data'].first(3).each do |location|
        puts "  - #{location['name']} (ID: #{location['location_id']})"
      end
    else
      puts "⚠️  No results found"
    end
  else
    puts "❌ ERROR: #{response.body}"
  end
end

# Test with some known locations
test_location("Paris", "France")
test_location("New York", "USA")
test_location("Tokyo", "Japan")
test_location("London", "United Kingdom")

puts "\n" + "="*60
puts "Test completed!"
puts "="*60
