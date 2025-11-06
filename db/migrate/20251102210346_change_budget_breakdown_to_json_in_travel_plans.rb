class ChangeBudgetBreakdownToJsonInTravelPlans < ActiveRecord::Migration[8.0]
  def up
    # For PostgreSQL, we need to specify how to cast the existing data
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute <<-SQL
        ALTER TABLE travel_plans 
        ALTER COLUMN budget_breakdown TYPE json 
        USING CASE 
          WHEN budget_breakdown IS NULL THEN NULL
          WHEN budget_breakdown::text = '' THEN NULL
          ELSE budget_breakdown::json 
        END;
      SQL
    else
      change_column :travel_plans, :budget_breakdown, :json
    end
  end

  def down
    change_column :travel_plans, :budget_breakdown, :text
  end
end
