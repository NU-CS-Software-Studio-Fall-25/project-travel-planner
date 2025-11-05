class AddItineraryToTravelPlans < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:travel_plans, :itinerary)
      add_column :travel_plans, :itinerary, :json
    end
  end
end
