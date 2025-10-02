json.extract! travel_plan, :id, :user_id, :destination_id, :start_date, :end_date, :status, :notes, :created_at, :updated_at
json.url travel_plan_url(travel_plan, format: :json)
