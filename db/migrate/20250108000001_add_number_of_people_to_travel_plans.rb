class AddNumberOfPeopleToTravelPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :travel_plans, :number_of_people, :integer, default: 1
  end
end
