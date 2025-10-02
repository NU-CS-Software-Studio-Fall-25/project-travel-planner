class CreateDestinations < ActiveRecord::Migration[8.0]
  def change
    create_table :destinations do |t|
      t.string :name
      t.string :country
      t.text :description
      t.boolean :visa_required
      t.integer :safety_score
      t.string :best_season
      t.decimal :average_cost
      t.decimal :latitude
      t.decimal :longitude

      t.timestamps
    end
  end
end
