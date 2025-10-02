class CreateTravelPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :travel_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.references :destination, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
