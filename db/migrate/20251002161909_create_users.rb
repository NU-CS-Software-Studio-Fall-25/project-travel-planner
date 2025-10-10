class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, index: { unique: true } # Add index for uniqueness and faster lookups
      t.string :password_digest # Add for has_secure_password

      t.timestamps
    end
  end
end
