class AddSubscriptionTierToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :subscription_tier, :string, default: 'free', null: false
  end
end
