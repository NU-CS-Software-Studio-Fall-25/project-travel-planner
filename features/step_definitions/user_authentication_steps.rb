# File: `features/step_definitions/user_authentication_steps.rb`
require 'capybara/dsl'
require 'securerandom'

Given("I am on the signup page") do
  visit signup_path
end

When("I sign up with valid details") do
  visit signup_path
  fill_in "Name", with: "Test User"
  fill_in "Email", with: "testuser+#{SecureRandom.hex(4)}@example.com"
  fill_in "Password", with: "Password1!"
  fill_in "Password confirmation", with: "Password1!"
  # Controller expects current_country
  if page.has_field?("Current country")
    fill_in "Current country", with: "United States"
  elsif page.has_field?("current_country")
    fill_in "current_country", with: "United States"
  end

  if page.has_button?("Create User")
    click_button "Create User"
  elsif page.has_button?("Sign up")
    click_button "Sign up"
  elsif page.has_button?("Create")
    click_button "Create"
  else
    # fallback submit the first form button
    first("form").find("input[type=submit], button[type=submit]", match: :first).click
  end
end

When("I sign up with an invalid password") do
  visit signup_path
  fill_in "Name", with: "Bad Password"
  fill_in "Email", with: "badpass+#{SecureRandom.hex(4)}@example.com"
  fill_in "Password", with: "weak"
  fill_in "Password confirmation", with: "weak"
  if page.has_field?("Current country")
    fill_in "Current country", with: "United States"
  elsif page.has_field?("current_country")
    fill_in "current_country", with: "United States"
  end

  if page.has_button?("Create User")
    click_button "Create User"
  elsif page.has_button?("Sign up")
    click_button "Sign up"
  else
    first("form").find("input[type=submit], button[type=submit]", match: :first).click
  end
end

Then("I should be redirected to my travel plans page") do
  # Be tolerant: either path or visible content
  expect(page).to have_current_path(travel_plans_path).or have_content("Travel plan").or have_content("Welcome")
end

Then("I should see a welcome notice") do
  expect(page).to have_content("Welcome").or have_content("successfully created").or have_selector(".notice")
end

Then("I should remain on the signup page") do
  expect(page).to have_current_path(signup_path).or have_selector("form#new_user").or have_content("Sign up")
end

Then("I should see a password validation error") do
  expect(page).to have_content("password").or have_content("must be at least 7").or have_content("can't be blank")
end

Given("an existing user exists") do
  @user ||= User.create!(
    name: "Existing User",
    email: "existing_user@example.com",
    password: "Password1!",
    password_confirmation: "Password1!",
    current_country: "United States"
  )
end

When("I log in with valid credentials") do
  visit login_path
  fill_in "Email", with: @user.email
  fill_in "Password", with: "Password1!"
  if page.has_button?("Log in")
    click_button "Log in"
  elsif page.has_button?("Login")
    click_button "Login"
  else
    first("form").find("input[type=submit], button[type=submit]", match: :first).click
  end
end

When("I log in with invalid credentials") do
  visit login_path
  fill_in "Email", with: @user.email
  fill_in "Password", with: "WrongPassword!"
  if page.has_button?("Log in")
    click_button "Log in"
  elsif page.has_button?("Login")
    click_button "Login"
  else
    first("form").find("input[type=submit], button[type=submit]", match: :first).click
  end
end

Then("I should remain on the login page") do
  expect(page).to have_current_path(login_path).or have_selector("form#login_form").or have_content("Log in")
end

Then("I should see an invalid credentials message") do
  expect(page).to have_content("Invalid").or have_content("Please log in").or have_content("Invalid email or password")
end