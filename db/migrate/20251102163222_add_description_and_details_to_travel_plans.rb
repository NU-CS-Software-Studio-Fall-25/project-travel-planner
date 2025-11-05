class AddDescriptionAndDetailsToTravelPlans < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:travel_plans, :description)
      add_column :travel_plans, :description, :text
    end

    unless column_exists?(:travel_plans, :details)
      add_column :travel_plans, :details, :text
    end
  end
end
