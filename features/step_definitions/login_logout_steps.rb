# features/step_definitions/authentication_steps.rb
Given('a user exists with name {string}, email {string}, and password {string}') do |name, email, password|
  # Use find_or_create_by! to prevent duplicate user errors when the background runs for each scenario.
  User.find_or_create_by!(email: email) do |user|
    user.name = name
    user.password = password
    user.password_confirmation = password
    user.current_country = 'United States' # Default value from schema
    user.terms_accepted = true
  end
end

Given('I am on the login page') do
  visit login_path
end

Given('I am logged in as the user {string} with password {string}') do |email, password|
  visit login_path
  fill_in 'email', with: email
  fill_in 'password', with: password
  click_button 'Login'
  # Adding an expectation to ensure login is successful before proceeding.
  expect(page).to have_current_path(travel_plans_path)
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I press {string}') do |button_name|
  click_button button_name
end

When('I click {string}') do |link_name|
  click_link link_name
end

When('I go to the login page') do
  visit login_path
end

Then('I should be on the travel plans page') do
  expect(page).to have_current_path(travel_plans_path)
end

Then('I should be on the login page') do
  expect(page).to have_current_path(login_path)
end

Then('I should be on the root page') do
  expect(page).to have_current_path(root_path)
end

# The following step is removed to resolve the ambiguous match error.
# It is assumed to be defined in another step definition file (e.g., travel_plans_steps.rb).
#
# Then('I should see {string}') do |content|
#   expect(page).to have_content(content)
# end
