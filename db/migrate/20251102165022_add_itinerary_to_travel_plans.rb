class AddItineraryToTravelPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :travel_plans, :itinerary, :json
  end
end
