# spec/factories/recommendation_feedbacks.rb
FactoryBot.define do
  factory :recommendation_feedback do
    association :user
    destination_city { "Paris" }
    destination_country { "France" }
    feedback_type { "like" }
    reason { "Beautiful architecture" }
    trip_type { "leisure" }
    travel_style { "cultural" }
    length_of_stay { 7 }

    trait :dislike do
      feedback_type { "dislike" }
      reason { "Too crowded" }
    end

    trait :adventure do
      travel_style { "adventure" }
      trip_type { "backpacking" }
    end
  end
end
