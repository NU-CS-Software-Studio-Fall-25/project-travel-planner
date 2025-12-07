require 'rails_helper'

RSpec.describe "PasswordResets", type: :request do
  # Include the time helpers to use methods like `travel_to`
  include ActiveSupport::Testing::TimeHelpers

  # Use a valid password and accept terms to pass validations
  let!(:user) { create(:user, email: 'test@example.com', password: 'Password123!', terms_accepted: true) }

  describe "GET /password_resets/new" do
    it "returns http success" do
      get new_password_reset_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /password_resets" do
    let(:generic_notice) { "If an account exists with that email, you will receive instructions to reset your password.\n    Please check your spam or junk folder if you do not see the email in your inbox." }

    context "with a valid, existing user email" do
      it "generates a reset token and sends an email" do
        expect {
          post password_resets_path, params: { email: user.email }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(user.reload.reset_password_token).not_to be_nil
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq(generic_notice)
      end
    end

    context "with a non-existent email" do
      it "does not send an email and shows a generic notice" do
        expect {
          post password_resets_path, params: { email: 'nonexistent@example.com' }
        }.not_to change { ActionMailer::Base.deliveries.count }

        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:notice]).to eq(generic_notice)
      end
    end

    context "with an OAuth user" do
      # Use a valid password and accept terms for the oauth user as well
      let!(:oauth_user) { create(:user, email: 'oauth@example.com', password: 'Password123!', provider: 'google', terms_accepted: true) }

      it "does not send an email and shows an alert" do
        expect {
          post password_resets_path, params: { email: oauth_user.email }
        }.not_to change { ActionMailer::Base.deliveries.count }

        expect(oauth_user.reload.reset_password_token).to be_nil
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to eq("Password reset is not available for accounts created via OAuth. Please sign in with your provider.")
      end
    end
  end

  describe "GET /password_resets/:id/edit" do
    let(:token) { SecureRandom.urlsafe_base64(24) }
    let(:alert_message) { "Reset token is invalid or expired. Please request a new one." }

    before do
      user.update_columns(
        reset_password_token: token,
        reset_password_sent_at: Time.current
      )
    end

    context "with a valid token" do
      it "returns http success" do
        get edit_password_reset_path(token)
        expect(response).to have_http_status(:success)
      end
    end

    context "with an invalid token" do
      it "redirects to the new password reset page" do
        get edit_password_reset_path('invalid_token')
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to eq(alert_message)
      end
    end

    context "with an expired token" do
      it "redirects to the new password reset page" do
        # Use travel_to to simulate time passing
        travel_to 3.hours.from_now do
          get edit_password_reset_path(token)
          expect(response).to redirect_to(new_password_reset_path)
          expect(flash[:alert]).to eq(alert_message)
        end
      end
    end
  end

  describe "PATCH /password_resets/:id" do
    let(:token) { SecureRandom.urlsafe_base64(24) }
    let(:alert_message) { "Reset token is invalid or expired. Please request a new one." }

    before do
      user.update_columns(
        reset_password_token: token,
        reset_password_sent_at: Time.current
      )
    end

    context "with valid parameters" do
      it "updates the password, logs the user in, and redirects" do
        # Use a valid password for the update
        patch password_reset_path(token), params: { user: { password: 'NewPassword123!', password_confirmation: 'NewPassword123!' } }
        user.reload
        expect(user.authenticate('NewPassword123!')).to be_truthy
        expect(user.reset_password_token).to be_nil
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(travel_plans_path)
        expect(flash[:notice]).to eq("Password has been reset.")
      end
    end

    context "with invalid parameters (password mismatch)" do
      it "re-renders the edit page" do
        patch password_reset_path(token), params: { user: { password: 'new', password_confirmation: 'mismatch' } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
        expect(user.reload.reset_password_token).to eq(token)
      end
    end

    context "with an invalid or expired token" do
      it "redirects to the new password reset page" do
        patch password_reset_path('invalid_token'), params: { user: { password: 'NewPassword123!', password_confirmation: 'NewPassword123!' } }
        expect(response).to redirect_to(new_password_reset_path)
        expect(flash[:alert]).to eq(alert_message)
      end
    end
  end
end
