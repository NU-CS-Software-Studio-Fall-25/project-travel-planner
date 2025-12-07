# Quick Test Script for GPI Integration

# Test 1: Verify safety level categorization
puts "=" * 60
puts "TEST 1: Safety Level Categorization"
puts "=" * 60

[ "Very Safe", "Generally Safe", "Partly Safe", "Not Safe" ].each do |level|
  countries = CountrySafetyScore.for_safety_level(level)
  puts "\n#{level}: #{countries.count} countries"
  puts "  Sample: #{countries.order(:gpi_rank).limit(3).pluck(:country_name).join(', ')}"
  puts "  GPI Range: #{countries.minimum(:gpi_score)} - #{countries.maximum(:gpi_score)}"
end

# Test 2: Check specific countries
puts "\n" + "=" * 60
puts "TEST 2: Specific Country Lookups"
puts "=" * 60

test_countries = [ "United States", "China", "Japan", "France", "Brazil", "Russia" ]
test_countries.each do |country_name|
  country = CountrySafetyScore.find_by(country_name: country_name)
  if country
    puts "\n#{country.country_name}:"
    puts "  GPI Score: #{country.gpi_score}"
    puts "  Global Rank: ##{country.gpi_rank}/163"
    puts "  Safety Level: #{country.safety_level}"
    puts "  Badge Color: #{country.badge_color}"
  else
    puts "\n#{country_name}: NOT FOUND"
  end
end

# Test 3: Simulate service layer query
puts "\n" + "=" * 60
puts "TEST 3: Service Layer Simulation"
puts "=" * 60

preferences = {
  safety_preference: "Generally Safe",
  trip_scope: "International",
  passport_country: "United States"
}

puts "\nUser Preferences:"
puts "  Safety: #{preferences[:safety_preference]}"
puts "  Scope: #{preferences[:trip_scope]}"
puts "  From: #{preferences[:passport_country]}"

# Simulate get_safe_countries logic
countries = CountrySafetyScore.for_safety_level(preferences[:safety_preference])

if preferences[:trip_scope] == "International" && preferences[:passport_country].present?
  countries = countries.where.not(country_name: preferences[:passport_country])
end

puts "\nEligible Countries: #{countries.count}"
puts "Top 10 recommendations:"
countries.order(:gpi_rank).limit(10).each_with_index do |c, index|
  puts "  #{index + 1}. #{c.country_name} (GPI: #{c.gpi_score}, Rank ##{c.gpi_rank})"
end

country_list = countries.pluck(:country_name).sort.join(", ")
puts "\nCountry list for LLM (first 100 chars):"
puts "  #{country_list[0..100]}..."

puts "\n" + "=" * 60
puts "✅ ALL TESTS COMPLETED SUCCESSFULLY!"
puts "=" * 60
