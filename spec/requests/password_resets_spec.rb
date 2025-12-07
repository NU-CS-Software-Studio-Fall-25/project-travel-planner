require 'rails_helper'

RSpec.describe "PasswordResets", type: :request do
  let(:user) { create(:user, terms_accepted: true) }

  describe "GET /new" do
    it "returns http success" do
      get "/password_resets/new"
      expect(response).to have_http_status(:success)
    end
  end
end
