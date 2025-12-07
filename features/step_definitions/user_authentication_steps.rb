# language: ruby
# file: features/step_definitions/smoke_auth_steps.rb
require 'capybara/dsl'
require 'securerandom'

module AuthStepHelpers
  include Capybara::DSL

  def fill_any_field(possible_locators, value)
    possible_locators = Array(possible_locators)
    possible_locators.each do |locator|
      begin
        fill_in(locator, with: value)
        return true
      rescue Capybara::ElementNotFound
        next
      end
    end

    # Try common attribute selectors if labels/names/ids aren't present
    if value =~ URI::MailTo::EMAIL_REGEXP
      el = first('input[type="email"], input[name$="[email]"], input[id$="_email"]')
      if el
        el.set(value)
        return true
      end
    else
      el = first('input[type="password"], input[name$="[password]"], input[id$="_password"]')
      if el
        el.set(value)
        return true
      end
    end

    false
  end

  def click_login_button
    ['Log in', 'Login', 'Sign in', 'Submit', 'Sign up'].each do |label|
      return true if (page.has_button?(label) && click_button(label))
    end

    # fallback: submit the first form
    form = first('form')
    if form
      submit = form.first('input[type=submit], button[type=submit]', match: :first)
      if submit
        submit.click
        return true
      end
    end

    false
  end
end

World(AuthStepHelpers)

Given("I am on the signup page") do
  visit signup_path
end

Then("I should remain on the signup page") do
  on_signup = (
    page.current_path == signup_path ||
      page.has_selector?('form#new_user') ||
      page.has_content?('Sign up') ||
      page.has_field?('user[email]') # heuristic
  )
  expect(on_signup).to be_truthy
end

Given("an existing user exists") do
  @user ||= User.find_by(email: "smoke_user@example.com")
  unless @user
    @user = User.create!(
      name: "Smoke User",
      email: "smoke_user@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      current_country: "United States",
      terms_accepted: true
    )
  end
end

When("I log in with invalid credentials") do
  visit login_path

  email_locators = ["Email", "E-mail", "Email address", "user[email]", "user_email", "email"]
  pass_locators  = ["Password", "password", "user[password]", "user_password"]

  filled_email = fill_any_field(email_locators, @user.email)
  filled_pass  = fill_any_field(pass_locators, "WrongPassword!")

  unless filled_email || filled_pass
    raise Capybara::ElementNotFound, "Unable to find email or password fields (tried: #{(email_locators + pass_locators).join(', ')})"
  end

  clicked = click_login_button
  unless clicked
    raise "Unable to find a submit button to perform login"
  end
end

Then("I should remain on the login page") do
  on_login = (
    page.current_path == login_path ||
      page.has_selector?('form#new_user, form#login_form') ||
      page.has_content?('Log in') ||
      page.has_content?('Invalid') ||
      page.has_content?('Invalid email or password')
  )
  expect(on_login).to be_truthy
end
