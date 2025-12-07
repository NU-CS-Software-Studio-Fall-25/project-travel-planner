# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  before_action :redirect_if_logged_in, only: [ :new, :create ]

  def new
    # Login form is now protected by the before_action
  end

  def create
    user = User.find_by(email: params[:email].downcase)
    if user && user.authenticate(params[:password])
      log_in user
      # Redirect to the travel plans index to create a new trip
      redirect_to travel_plans_path, notice: "Welcome back, #{user.name}! Let's plan a new trip."
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  # OAuth callback handler
  def google_oauth2
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    if user.persisted?
      # Check if this is a new user (created_at and updated_at are very close)
      # OR if they never completed profile (we check using session)
      is_new_user = (user.updated_at - user.created_at) < 5.seconds

      if is_new_user
        # Store user info in session and redirect to complete profile
        session[:omniauth_user_id] = user.id
        redirect_to complete_profile_path, notice: "Please complete your profile to continue."
      else
        # Existing user - just log them in
        log_in user
        redirect_to travel_plans_path, notice: "Welcome back, #{user.name}!"
      end
    else
      redirect_to signup_path, alert: "Authentication failed. Please try again."
    end
  end

  # Handle OAuth failures
  def failure
    redirect_to login_path, alert: "Authentication failed: #{params[:message]}"
  end

  def destroy
    log_out
    redirect_to root_path, notice: "You have been logged out."
  end

  private

  def log_in(user)
    session[:user_id] = user.id
  end

  def log_out
    session.delete(:user_id)
    session.delete(:omniauth_user_id)
    @current_user = nil
  end

  def redirect_if_logged_in
    if logged_in?
      redirect_to travel_plans_path, notice: "You are already logged in."
    end
  end
end
