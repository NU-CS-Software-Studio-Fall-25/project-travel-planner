class AddDescriptionAndDetailsToTravelPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :travel_plans, :description, :text
    add_column :travel_plans, :details, :text
  end
end
