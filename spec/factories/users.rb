# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password1!" }
    password_confirmation { "Password1!" }
    current_country { "United States" }
    subscription_tier { "free" }
    recommendation_generations_used { 0 }
    generations_reset_at { Time.current }

    trait :premium do
      subscription_tier { "premium" }
    end

    trait :oauth_user do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google_uid_#{n}" }
      password { nil }
      password_confirmation { nil }
      oauth_token { "mock_oauth_token" }
      email_verified { true }
    end

    trait :at_generation_limit do
      recommendation_generations_used { User::FREE_TIER_GENERATION_LIMIT }
    end
  end
end
