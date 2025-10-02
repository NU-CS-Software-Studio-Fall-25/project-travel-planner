require "application_system_test_case"

class TravelPlansTest < ApplicationSystemTestCase
  setup do
    @travel_plan = travel_plans(:one)
  end

  test "visiting the index" do
    visit travel_plans_url
    assert_selector "h1", text: "Travel plans"
  end

  test "should create travel plan" do
    visit travel_plans_url
    click_on "New travel plan"

    fill_in "Destination", with: @travel_plan.destination_id
    fill_in "End date", with: @travel_plan.end_date
    fill_in "Notes", with: @travel_plan.notes
    fill_in "Start date", with: @travel_plan.start_date
    fill_in "Status", with: @travel_plan.status
    fill_in "User", with: @travel_plan.user_id
    click_on "Create Travel plan"

    assert_text "Travel plan was successfully created"
    click_on "Back"
  end

  test "should update Travel plan" do
    visit travel_plan_url(@travel_plan)
    click_on "Edit this travel plan", match: :first

    fill_in "Destination", with: @travel_plan.destination_id
    fill_in "End date", with: @travel_plan.end_date
    fill_in "Notes", with: @travel_plan.notes
    fill_in "Start date", with: @travel_plan.start_date
    fill_in "Status", with: @travel_plan.status
    fill_in "User", with: @travel_plan.user_id
    click_on "Update Travel plan"

    assert_text "Travel plan was successfully updated"
    click_on "Back"
  end

  test "should destroy Travel plan" do
    visit travel_plan_url(@travel_plan)
    click_on "Destroy this travel plan", match: :first

    assert_text "Travel plan was successfully destroyed"
  end
end
