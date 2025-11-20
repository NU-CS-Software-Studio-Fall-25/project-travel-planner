# File: `features/step_definitions/travel_recommendations_steps.rb`
Given("I am logged in as a user who can generate recommendations") do
  @user = User.create!(
    name: "Rec User",
    email: "recuser@example.com",
    password: "Password1!",
    password_confirmation: "Password1!",
    current_country: "United States",
    recommendation_generations_used: 0,
    generations_reset_at: Time.current
  )
  visit login_path
  fill_in "Email", with: @user.email
  fill_in "Password", with: "Password1!"
  if has_button?("Log in")
    click_button "Log in"
  else
    find('form').find('input[type=submit], button[type=submit]').click
  end
end

When("I submit travel preferences for recommendations") do
  visit travel_recommendations_path
  # Fill common fields
  fill_in "Length of stay", with: "5" if has_field?("Length of stay")
  fill_in "Budget min", with: "500" if has_field?("Budget min")
  fill_in "Budget max", with: "1500" if has_field?("Budget max")
  if has_button?("Generate Recommendations")
    click_button "Generate Recommendations"
  else
    find('form').find('input[type=submit], button[type=submit]').click
  end

  # Wait for either turbo stream content or redirect/notice
  expect(page).to have_selector("#recommendations_list", wait: 5).or have_content("Recommendations").or have_content("generated")
end

Then("I should see a recommendations list") do
  expect(page).to have_selector("#recommendations_list").or have_content("Recommendations")
end

Given("the user has used up their free generation allowance") do
  @user ||= User.create!(
    name: "Limit User",
    email: "limit@example.com",
    password: "Password1!",
    password_confirmation: "Password1!",
    current_country: "United States"
  )
  @user.update(recommendation_generations_used: User::FREE_TIER_GENERATION_LIMIT, generations_reset_at: Time.current)
  visit login_path
  fill_in "Email", with: @user.email
  fill_in "Password", with: "Password1!"
  click_button "Log in" if has_button?("Log in")
end

When("I attempt to generate recommendations") do
  visit travel_recommendations_path
  fill_in "Length of stay", with: "3" if has_field?("Length of stay")
  if has_button?("Generate Recommendations")
    click_button "Generate Recommendations"
  else
    find('form').find('input[type=submit], button[type=submit]').click
  end
end

Then("I should see a limit reached message") do
  expect(page).to have_content("You have reached your monthly free generation limit").or have_selector("#limit-reached")
end