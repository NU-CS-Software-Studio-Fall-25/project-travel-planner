require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: "Users"
  end

  test "should create user" do
    visit users_url
    click_on "New user"

    fill_in "Budget max", with: @user.budget_max
    fill_in "Budget min", with: @user.budget_min
    fill_in "Email", with: @user.email
    fill_in "Name", with: @user.name
    fill_in "Passport country", with: @user.passport_country
    fill_in "Preferred travel season", with: @user.preferred_travel_season
    fill_in "Safety preference", with: @user.safety_preference
    click_on "Create User"

    assert_text "User was successfully created"
    click_on "Back"
  end

  test "should update User" do
    visit user_url(@user)
    click_on "Edit this user", match: :first

    fill_in "Budget max", with: @user.budget_max
    fill_in "Budget min", with: @user.budget_min
    fill_in "Email", with: @user.email
    fill_in "Name", with: @user.name
    fill_in "Passport country", with: @user.passport_country
    fill_in "Preferred travel season", with: @user.preferred_travel_season
    fill_in "Safety preference", with: @user.safety_preference
    click_on "Update User"

    assert_text "User was successfully updated"
    click_on "Back"
  end

  test "should destroy User" do
    visit user_url(@user)
    click_on "Destroy this user", match: :first

    assert_text "User was successfully destroyed"
  end
end
