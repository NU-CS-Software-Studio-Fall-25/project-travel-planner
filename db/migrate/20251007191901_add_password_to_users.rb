class AddPasswordToUsers < ActiveRecord::Migration[8.0]
  def change
    # This migration is not needed because password_digest was already 
    # included in the create_users migration
    # add_column :users, :password_digest, :string
  end
end
