# spec/views/password_resets/edit.html.erb_spec.rb
require 'rails_helper'

RSpec.describe "password_resets/edit.html.erb", type: :view do
  let(:user) { User.new(id: 1, email: "test@example.com") }

  before(:each) do
    assign(:user, user)
    # The view uses params[:id] in the URL helper
    allow(view).to receive(:params).and_return({ id: 'some_reset_token' })
    render
  end

  it "renders the 'Reset your password' heading" do
    expect(rendered).to have_selector('h1', text: 'Reset your password')
  end

  it "renders a form to reset the password" do
    expect(rendered).to have_selector("form[action='#{password_reset_path('some_reset_token')}']")
  end

  it "renders a 'Show Passwords' button" do
    expect(rendered).to have_button('Show Passwords')
  end

  it "renders an 'Update password' submit button" do
    expect(rendered).to have_button('Update password')
  end
end