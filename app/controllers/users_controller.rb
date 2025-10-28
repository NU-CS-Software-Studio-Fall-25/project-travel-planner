# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :require_login, only: [:show, :edit, :update, :destroy]
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user, only: [:show, :edit, :update, :destroy]
  before_action :redirect_if_logged_in, only: [:new, :create]

  # GET /users or /users.json
  def index
    @users = User.all
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        log_in @user # Log in the user after successful signup
        format.html { redirect_to travel_plans_path, notice: "Welcome! Your account was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to user_url(@user), notice: "User was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_url, notice: "User was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :passport_country, :current_country)
  end

  def log_in(user)
    session[:user_id] = user.id
  end

  def redirect_if_logged_in
    if logged_in?
      redirect_to travel_plans_path, notice: "You are already logged in."
    end
  end

  # Ensure users can only access their own profile
  def authorize_user
    unless @user == current_user
      flash[:alert] = "You are not authorized to access this page."
      redirect_to travel_plans_path
    end
  end
end
