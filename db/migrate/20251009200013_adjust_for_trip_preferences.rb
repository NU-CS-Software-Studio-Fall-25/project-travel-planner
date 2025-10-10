class AdjustForTripPreferences < ActiveRecord::Migration[8.0]
  def change
    # Remove preference columns from the users table
    remove_column :users, :passport_country, :string
    remove_column :users, :budget_min, :decimal
    remove_column :users, :budget_max, :decimal
    remove_column :users, :preferred_travel_season, :string
    remove_column :users, :safety_preference, :integer

    # Add more detailed preference columns to the travel_plans table
    add_column :travel_plans, :name, :string, comment: "A name for this specific trip plan"
    add_column :travel_plans, :passport_country, :string
    add_column :travel_plans, :budget_min, :decimal
    add_column :travel_plans, :budget_max, :decimal
    add_column :travel_plans, :safety_preference, :integer
    add_column :travel_plans, :travel_style, :string, comment: "e.g., Luxury, Leisure, Adventure"
    add_column :travel_plans, :length_of_stay, :integer, comment: "Duration of the trip in days"
    add_column :travel_plans, :travel_month, :string
    add_column :travel_plans, :general_purpose, :string, comment: "e.g., Vacation, Business, Exploration"
    add_column :travel_plans, :trip_scope, :string, comment: "International or Domestic"
    add_column :travel_plans, :trip_type, :string, comment: "Solo, Couple, Family, or Group"

    # New columns for itinerary, details, and description
    add_column :travel_plans, :itinerary, :text, comment: "Detailed day-by-day travel itinerary"
    add_column :travel_plans, :details, :text, comment: "Additional trip details or notes"
    add_column :travel_plans, :description, :text, comment: "A short description summarizing the trip"
  end
end
