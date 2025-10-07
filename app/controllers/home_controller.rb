class HomeController < ApplicationController
  def index
    # Redirect logged-in users to their profile page
    if logged_in?
      redirect_to current_user
    end
    # Non-logged-in users will see the Rails home page (not the static index.html)
  end
end
