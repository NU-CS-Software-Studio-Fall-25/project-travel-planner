class AddMissingFieldsToTravelPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :travel_plans, :safety_score, :integer
    add_column :travel_plans, :visa_info, :string
    add_column :travel_plans, :budget_breakdown, :text
    add_column :travel_plans, :destination_country, :string
  end
end
