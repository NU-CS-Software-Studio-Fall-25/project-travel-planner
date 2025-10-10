# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Sample data for travel planner

# Create sample destinations
destinations = [
  {
    name: "Tokyo",
    country: "Japan",
    description: "A vibrant metropolis blending traditional culture with cutting-edge technology.",
    visa_required: true,
    safety_score: 9,
    best_season: "Spring",
    average_cost: 150.0,
    latitude: 35.6762,
    longitude: 139.6503
  },
  {
    name: "Reykjavik",
    country: "Iceland",
    description: "Gateway to stunning natural wonders including geysers, waterfalls, and Northern Lights.",
    visa_required: false,
    safety_score: 10,
    best_season: "Summer",
    average_cost: 180.0,
    latitude: 64.1466,
    longitude: -21.9426
  },
  {
    name: "Lisbon",
    country: "Portugal",
    description: "Charming coastal capital with colorful neighborhoods, rich history, and delicious cuisine.",
    visa_required: false,
    safety_score: 8,
    best_season: "Spring",
    average_cost: 80.0,
    latitude: 38.7223,
    longitude: -9.1393
  },
  {
    name: "Costa Rica",
    country: "Costa Rica",
    description: "Tropical paradise perfect for eco-tourism, wildlife watching, and adventure sports.",
    visa_required: false,
    safety_score: 7,
    best_season: "Winter",
    average_cost: 100.0,
    latitude: 9.7489,
    longitude: -83.7534
  },
  {
    name: "Singapore",
    country: "Singapore",
    description: "Modern city-state offering world-class dining, shopping, and cultural experiences.",
    visa_required: true,
    safety_score: 9,
    best_season: "Winter",
    average_cost: 120.0,
    latitude: 1.3521,
    longitude: 103.8198
  },
  {
    name: "Amsterdam",
    country: "Netherlands",
    description: "Picturesque canal city famous for art museums, cycling culture, and vibrant nightlife.",
    visa_required: false,
    safety_score: 8,
    best_season: "Summer",
    average_cost: 110.0,
    latitude: 52.3676,
    longitude: 4.9041
  },
  {
    name: "Bangkok",
    country: "Thailand",
    description: "Bustling capital known for ornate shrines, vibrant street markets, and incredible street food.",
    visa_required: true,
    safety_score: 6,
    best_season: "Winter",
    average_cost: 60.0,
    latitude: 13.7563,
    longitude: 100.5018
  },
  {
    name: "Sydney",
    country: "Australia",
    description: "Harbor city famous for its Opera House, beautiful beaches, and laid-back lifestyle.",
    visa_required: true,
    safety_score: 9,
    best_season: "Summer",
    average_cost: 170.0,
    latitude: -33.8688,
    longitude: 151.2093
  },
  {
    name: "Barcelona",
    country: "Spain",
    description: "Cosmopolitan city renowned for art, architecture, and Mediterranean cuisine.",
    visa_required: false,
    safety_score: 7,
    best_season: "Spring",
    average_cost: 95.0,
    latitude: 41.3851,
    longitude: 2.1734
  },
  {
    name: "Marrakech",
    country: "Morocco",
    description: "Imperial city with bustling souks, stunning palaces, and rich Berber culture.",
    visa_required: false,
    safety_score: 6,
    best_season: "Spring",
    average_cost: 70.0,
    latitude: 31.6295,
    longitude: -7.9811
  },
  {
    name: "Rio de Janeiro",
    country: "Brazil",
    description: "Vibrant city known for Carnival, beautiful beaches, and the iconic Christ the Redeemer statue.",
    visa_required: true,
    safety_score: 5,
    best_season: "Summer",
    average_cost: 85.0,
    latitude: -22.9068,
    longitude: -43.1729
  },
  {
    name: "Prague",
    country: "Czech Republic",
    description: "Fairy-tale city with medieval architecture, historic castles, and famous Czech beer.",
    visa_required: false,
    safety_score: 8,
    best_season: "Spring",
    average_cost: 65.0,
    latitude: 50.0755,
    longitude: 14.4378
  },
  {
    name: "Dubai",
    country: "UAE",
    description: "Ultra-modern city with luxury shopping, futuristic architecture, and desert adventures.",
    visa_required: true,
    safety_score: 9,
    best_season: "Winter",
    average_cost: 140.0,
    latitude: 25.2048,
    longitude: 55.2708
  },
  {
    name: "Edinburgh",
    country: "Scotland",
    description: "Historic capital with medieval Old Town, elegant Georgian New Town, and famous festivals.",
    visa_required: false,
    safety_score: 9,
    best_season: "Summer",
    average_cost: 130.0,
    latitude: 55.9533,
    longitude: -3.1883
  },
  {
    name: "Cape Town",
    country: "South Africa",
    description: "Stunning coastal city with Table Mountain, wine regions, and rich cultural heritage.",
    visa_required: false,
    safety_score: 6,
    best_season: "Summer",
    average_cost: 75.0,
    latitude: -33.9249,
    longitude: 18.4241
  },
  {
    name: "Seoul",
    country: "South Korea",
    description: "Dynamic capital blending ancient traditions with modern technology and K-pop culture.",
    visa_required: false,
    safety_score: 8,
    best_season: "Spring",
    average_cost: 90.0,
    latitude: 37.5665,
    longitude: 126.9780
  },
  {
    name: "Istanbul",
    country: "Turkey",
    description: "Transcontinental city bridging Europe and Asia with rich Byzantine and Ottoman history.",
    visa_required: true,
    safety_score: 6,
    best_season: "Spring",
    average_cost: 55.0,
    latitude: 41.0082,
    longitude: 28.9784
  },
  {
    name: "Vancouver",
    country: "Canada",
    description: "Pacific coastal city surrounded by mountains, known for outdoor activities and multiculturalism.",
    visa_required: false,
    safety_score: 9,
    best_season: "Summer",
    average_cost: 125.0,
    latitude: 49.2827,
    longitude: -123.1207
  },
  {
    name: "Buenos Aires",
    country: "Argentina",
    description: "Passionate city famous for tango, European architecture, and incredible steakhouses.",
    visa_required: false,
    safety_score: 6,
    best_season: "Spring",
    average_cost: 70.0,
    latitude: -34.6037,
    longitude: -58.3816
  },
  {
    name: "Bali",
    country: "Indonesia",
    description: "Tropical island paradise with ancient temples, rice terraces, and world-class surfing.",
    visa_required: true,
    safety_score: 7,
    best_season: "Summer",
    average_cost: 50.0,
    latitude: -8.3405,
    longitude: 115.0920
  },
  {
    name: "Vienna",
    country: "Austria",
    description: "Imperial capital renowned for classical music, grand palaces, and coffeehouse culture.",
    visa_required: false,
    safety_score: 9,
    best_season: "Spring",
    average_cost: 105.0,
    latitude: 48.2082,
    longitude: 16.3738
  },
  {
    name: "Stockholm",
    country: "Sweden",
    description: "Scandinavian capital built on 14 islands, famous for design, innovation, and archipelago beauty.",
    visa_required: false,
    safety_score: 9,
    best_season: "Summer",
    average_cost: 160.0,
    latitude: 59.3293,
    longitude: 18.0686
  }
]

# Create destinations
destinations.each do |dest_attrs|
  destination = Destination.find_or_create_by(name: dest_attrs[:name], country: dest_attrs[:country]) do |dest|
    dest.assign_attributes(dest_attrs)
  end
  puts "Created/Found destination: #{destination.name}, #{destination.country}"
end

# Create sample users
users = [
  {
    name: "Alex Chen",
    email: "alex@example.com",
    passport_country: "USA",
    budget_min: 100.0,
    budget_max: 200.0,
    preferred_travel_season: "Spring",
    safety_preference: 8
  },
  {
    name: "Maria Garcia",
    email: "maria@example.com",
    passport_country: "Spain",
    budget_min: 50.0,
    budget_max: 120.0,
    preferred_travel_season: "Summer",
    safety_preference: 7
  },
  {
    name: "John Smith",
    email: "john@example.com",
    passport_country: "Canada",
    budget_min: 80.0,
    budget_max: 150.0,
    preferred_travel_season: "Winter",
    safety_preference: 9
  },
  {
    name: "Emma Wilson",
    email: "emma@example.com",
    passport_country: "UK",
    budget_min: 90.0,
    budget_max: 180.0,
    preferred_travel_season: "Spring",
    safety_preference: 8
  },
  {
    name: "Yuki Tanaka",
    email: "yuki@example.com",
    passport_country: "Japan",
    budget_min: 120.0,
    budget_max: 250.0,
    preferred_travel_season: "Summer",
    safety_preference: 9
  }
]

users.each do |user_attrs|
  user = User.find_or_create_by(email: user_attrs[:email]) do |u|
    u.assign_attributes(user_attrs)
  end
  puts "Created/Found user: #{user.name} (#{user.email})"
end

puts "Sample data created successfully!"
puts "#{Destination.count} destinations and #{User.count} users in database."
