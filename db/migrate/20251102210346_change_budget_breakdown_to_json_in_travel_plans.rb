class ChangeBudgetBreakdownToJsonInTravelPlans < ActiveRecord::Migration[8.0]
  def change
    change_column :travel_plans, :budget_breakdown, :json
  end
end
