# spec/factories/destinations.rb
FactoryBot.define do
  factory :destination do
    sequence(:name) { |n| "Destination #{n}" }
    sequence(:city) { |n| "City #{n}" }
    country { "France" }
    description { "A beautiful place to visit" }
    latitude { 48.8566 }
    longitude { 2.3522 }
    safety_score { 5 }
    best_season { "Spring and Fall" }

    trait :unsafe do
      safety_score { 8 }
    end

    trait :safe do
      safety_score { 2 }
    end

    trait :domestic do
      country { "United States" }
      city { "New York" }
    end
  end
end
