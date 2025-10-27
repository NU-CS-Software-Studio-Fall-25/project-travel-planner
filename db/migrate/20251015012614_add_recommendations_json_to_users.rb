class AddRecommendationsJsonToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :recommendations_json, :text
  end
end
