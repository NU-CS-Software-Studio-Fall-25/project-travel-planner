# spec/factories/travel_plans.rb
FactoryBot.define do
  factory :travel_plan do
    association :user
    association :destination
    sequence(:name) { |n| "Trip #{n}" }
    description { "A wonderful vacation" }
    start_date { 1.week.from_now }
    end_date { 2.weeks.from_now }
    status { "planned" }
    notes { "Don't forget passport" }
    budget_min { 1000.0 }
    budget_max { 3000.0 }
    itinerary { { "day_1" => "Arrival", "day_2" => "Sightseeing" } }

    trait :booked do
      status { "booked" }
    end

    trait :completed do
      status { "completed" }
      start_date { 2.weeks.ago }
      end_date { 1.week.ago }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
