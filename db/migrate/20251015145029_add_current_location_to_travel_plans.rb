class AddCurrentLocationToTravelPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :travel_plans, :current_location, :string
  end
end
