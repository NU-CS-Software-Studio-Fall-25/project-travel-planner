json.extract! destination, :id, :name, :country, :description, :visa_required, :safety_score, :best_season, :average_cost, :latitude, :longitude, :created_at, :updated_at
json.url destination_url(destination, format: :json)
