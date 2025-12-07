class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [ :show, :update, :destroy ]

  # GET /api/v1/users
  def index
    @users = User.all
    render_success(@users)
  end

  # GET /api/v1/users/1
  def show
    render_success(@user)
  end

  # POST /api/v1/users
  def create
    @user = User.new(user_params)

    if @user.save
      render_success(@user, "User created successfully")
    else
      render_error(@user.errors.full_messages.join(", "))
    end
  end

  # PATCH/PUT /api/v1/users/1
  def update
    if @user.update(user_params)
      render_success(@user, "User updated successfully")
    else
      render_error(@user.errors.full_messages.join(", "))
    end
  end

  # DELETE /api/v1/users/1
  def destroy
    @user.destroy!
    render_success({}, "User deleted successfully")
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("User not found")
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :passport_country, :budget_min, :budget_max, :preferred_travel_season, :safety_preference)
  end
end
