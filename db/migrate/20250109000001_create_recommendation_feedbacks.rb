class CreateRecommendationFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :recommendation_feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :destination_city, null: false
      t.string :destination_country, null: false
      t.string :trip_type
      t.string :travel_style
      t.integer :budget_min
      t.integer :budget_max
      t.integer :length_of_stay
      t.string :feedback_type, null: false # 'like' or 'dislike'
      t.text :reason # Optional: why they liked/disliked it

      t.timestamps
    end

    # Prevent duplicate feedback for same destination
    add_index :recommendation_feedbacks, [ :user_id, :destination_city, :destination_country ],
              unique: true,
              name: 'index_feedbacks_on_user_and_destination'
  end
end
