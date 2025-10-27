class AddCityToDestinations < ActiveRecord::Migration[8.0]
  def change
    add_column :destinations, :city, :string
  end
end
