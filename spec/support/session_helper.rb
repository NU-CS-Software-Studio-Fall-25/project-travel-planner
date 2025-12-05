# spec/support/session_helper.rb
module SessionHelper
  # Helper method to simulate user login in controller/request specs
  def log_in_as(user)
    if respond_to?(:session)
      session[:user_id] = user.id
    end
  end

  # Helper method to get current user
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
