json.extract! user, :id, :name, :email, :passport_country, :budget_min, :budget_max, :preferred_travel_season, :safety_preference, :created_at, :updated_at
json.url user_url(user, format: :json)
