class ChangeCurrentCountryDefaultInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :current_country, from: nil, to: 'United States'

    # Update existing users with nil current_country to United States
    reversible do |dir|
      dir.up do
        User.where(current_country: nil).update_all(current_country: 'United States')
      end
    end
  end
end
