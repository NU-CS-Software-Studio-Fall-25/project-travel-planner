# ruby
class PasswordResetsController < ApplicationController
  # Show form to request password reset
  def new
  end

  # Create reset token and send email (if allowed)
  def create
    email = params[:email].to_s.downcase.strip
    user = User.where("lower(email) = ?", email).first

    # Always respond with the same message to avoid account enumeration
    generic_notice = "If an account exists with that email, you will receive instructions to reset your password.
    Please check your spam or junk folder if you do not see the email in your inbox."

    if user.nil?
      redirect_to new_password_reset_path, notice: generic_notice
      return
    end

    if user.provider.present?
      redirect_to new_password_reset_path, alert: "Password reset is not available for accounts created via OAuth. Please sign in with your provider."
      return
    end

    user.reset_password_token = SecureRandom.urlsafe_base64(24)
    user.reset_password_sent_at = Time.current
    user.save(validate: false)

    UserMailer.reset_password(user).deliver_now

    redirect_to login_path, notice: generic_notice
  end

  # Page to enter new password
  def edit
    @user = User.find_by(reset_password_token: params[:id])
    if @user.nil? || token_expired?(@user)
      redirect_to new_password_reset_path, alert: "Reset token is invalid or expired. Please request a new one."
    end
  end

  # Apply the new password
  def update
    @user = User.find_by(reset_password_token: params[:id])
    if @user.nil? || token_expired?(@user)
      redirect_to new_password_reset_path, alert: "Reset token is invalid or expired. Please request a new one."
      return
    end

    if @user.provider.present?
      redirect_to login_path, alert: "Password cannot be changed for accounts created via OAuth."
      return
    end

    if @user.update(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
      # Clear token and sign in
      @user.update(reset_password_token: nil, reset_password_sent_at: nil)
      session[:user_id] = @user.id
      redirect_to travel_plans_path, notice: "Password has been reset."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def token_expired?(user)
    user.reset_password_sent_at.blank? || user.reset_password_sent_at < 2.hours.ago
  end
end
