class CreateRecommendations < ActiveRecord::Migration[8.0]
  def change
    create_table :recommendations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :destination, null: false, foreign_key: true
      t.text :openai_response
      t.decimal :recommendation_score
      t.text :reasons

      t.timestamps
    end
  end
end
