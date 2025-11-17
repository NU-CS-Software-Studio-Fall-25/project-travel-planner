# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_09_052328) do
  create_table "country_safety_scores", force: :cascade do |t|
    t.string "country_name", null: false
    t.decimal "gpi_score", precision: 5, scale: 3, null: false
    t.integer "gpi_rank", null: false
    t.integer "year", default: 2025, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_name"], name: "index_country_safety_scores_on_country_name"
    t.index ["gpi_rank"], name: "index_country_safety_scores_on_gpi_rank"
    t.index ["gpi_score"], name: "index_country_safety_scores_on_gpi_score"
    t.index ["year", "country_name"], name: "index_country_safety_scores_on_year_and_country_name", unique: true
  end

  create_table "destinations", force: :cascade do |t|
    t.string "name"
    t.string "country"
    t.text "description"
    t.boolean "visa_required"
    t.integer "safety_score"
    t.string "best_season"
    t.decimal "average_cost"
    t.decimal "latitude"
    t.decimal "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
  end

  create_table "recommendation_feedbacks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "destination_city", null: false
    t.string "destination_country", null: false
    t.string "trip_type"
    t.string "travel_style"
    t.integer "budget_min"
    t.integer "budget_max"
    t.integer "length_of_stay"
    t.string "feedback_type", null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "destination_city", "destination_country"], name: "index_feedbacks_on_user_and_destination", unique: true
    t.index ["user_id"], name: "index_recommendation_feedbacks_on_user_id"
  end

  create_table "recommendations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "destination_id", null: false
    t.text "openai_response"
    t.decimal "recommendation_score"
    t.text "reasons"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_recommendations_on_destination_id"
    t.index ["user_id"], name: "index_recommendations_on_user_id"
  end

  create_table "travel_plans", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "destination_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "passport_country"
    t.decimal "budget_min"
    t.decimal "budget_max"
    t.integer "safety_preference"
    t.string "travel_style"
    t.integer "length_of_stay"
    t.string "travel_month"
    t.string "general_purpose"
    t.string "trip_scope"
    t.string "trip_type"
    t.integer "safety_score"
    t.string "visa_info"
    t.json "budget_breakdown"
    t.string "destination_country"
    t.string "current_location"
    t.text "description"
    t.text "details"
    t.json "itinerary"
    t.integer "number_of_people", default: 1
    t.integer "number_of_travelers", default: 1
    t.index ["destination_id"], name: "index_travel_plans_on_destination_id"
    t.index ["user_id"], name: "index_travel_plans_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.text "recommendations_json"
    t.string "current_country", default: "United States"
    t.string "subscription_tier", default: "free", null: false
  end

  add_foreign_key "recommendation_feedbacks", "users"
  add_foreign_key "recommendations", "destinations"
  add_foreign_key "recommendations", "users"
  add_foreign_key "travel_plans", "destinations"
  add_foreign_key "travel_plans", "users"
end
