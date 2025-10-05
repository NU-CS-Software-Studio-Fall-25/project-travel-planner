class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :passport_country
      t.decimal :budget_min
      t.decimal :budget_max
      t.string :preferred_travel_season
      t.integer :safety_preference

      t.timestamps
    end
  end
end
