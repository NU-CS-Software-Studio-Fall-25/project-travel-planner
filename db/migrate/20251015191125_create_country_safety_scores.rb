class CreateCountrySafetyScores < ActiveRecord::Migration[8.0]
  def change
    create_table :country_safety_scores do |t|
      t.string :country_name, null: false
      t.decimal :gpi_score, precision: 5, scale: 3, null: false
      t.integer :gpi_rank, null: false
      t.integer :year, null: false, default: 2025

      t.timestamps
    end

    add_index :country_safety_scores, :country_name
    add_index :country_safety_scores, :gpi_score
    add_index :country_safety_scores, :gpi_rank
    add_index :country_safety_scores, [ :year, :country_name ], unique: true
  end
end
