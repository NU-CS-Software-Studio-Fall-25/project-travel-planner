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
