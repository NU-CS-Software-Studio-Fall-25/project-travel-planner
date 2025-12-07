# spec/views/password_resets/new.html.erb_spec.rb
require 'rails_helper'

RSpec.describe "password_resets/new.html.erb", type: :view do
  before(:each) do
    render
  end

  it "renders the 'Forgot your password?' heading" do
    expect(rendered).to have_selector('h1', text: 'Forgot your password?')
  end

  it "renders the instructional text" do
    expect(rendered).to have_selector('p', text: "Enter your email and we'll send instructions to reset your password.")
  end

  it "renders a form to request a password reset" do
    expect(rendered).to have_selector("form[action='#{password_resets_path}'][method='post']")
  end

  it "renders an email input field" do
    expect(rendered).to have_field('email', type: 'email')
  end

  it "renders a submit button" do
    expect(rendered).to have_button('Send reset instructions')
  end
end
