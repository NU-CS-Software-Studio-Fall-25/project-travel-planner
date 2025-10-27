# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  before_action :redirect_if_logged_in, only: [:new, :create]

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
      flash.now[:alert] = 'Invalid email or password'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_out
    redirect_to root_path, notice: 'You have been logged out.'
  end

  private

  def log_in(user)
    session[:user_id] = user.id
  end

  def log_out
    session.delete(:user_id)
    @current_user = nil
  end

  def redirect_if_logged_in
    if logged_in?
      redirect_to travel_plans_path, notice: "You are already logged in."
    end
  end
end
