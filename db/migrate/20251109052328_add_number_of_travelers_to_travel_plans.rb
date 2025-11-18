class AddNumberOfTravelersToTravelPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :travel_plans, :number_of_travelers, :integer, default: 1, comment: "Number of people traveling (1-10+)"
  end
end
