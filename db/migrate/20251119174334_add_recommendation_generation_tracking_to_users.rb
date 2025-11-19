class AddRecommendationGenerationTrackingToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :recommendation_generations_used, :integer, default: 0
    add_column :users, :generations_reset_at, :datetime
  end
end
