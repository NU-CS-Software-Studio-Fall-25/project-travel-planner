# spec/factories/travel_plans.rb
FactoryBot.define do
  factory :travel_plan do
    name { "Trip to #{Faker::Address.city}" }
    description { "Planning an exciting adventure to explore new places and experience different cultures." }
    start_date { 1.month.from_now }
    end_date { 1.month.from_now + 7.days }
    status { 'planned' }

    # Use an association for the user, which is the correct approach.
    # This ensures a user is created and linked without inheriting its attributes.
    association :user

    # Also associate a destination.
    association :destination
  end
end
