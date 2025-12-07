# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :require_login, only: [ :show, :edit, :update, :destroy, :change_password, :update_password, :verify_password ]
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :change_password, :update_password, :verify_password ]
  before_action :authorize_user, only: [ :show, :edit, :update, :destroy, :change_password, :update_password, :verify_password ]
  before_action :redirect_if_logged_in, only: [ :new, :create ]

  # GET /users or /users.json
  def index
    # order users (change as desired)
    @pagy, @users = pagy(User.order(:name), items: 25)
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new

    # Pre-fill from OAuth if coming from Google Sign In
    if session[:omniauth_user_id]
      oauth_user = User.find_by(id: session[:omniauth_user_id])
      if oauth_user
        @user.name = oauth_user.name
        @user.email = oauth_user.email
        @user.provider = oauth_user.provider
        @user.uid = oauth_user.uid
      end
    end
  end

  # Complete profile after OAuth (similar to new but for existing OAuth users)
  def complete_profile
    @user = User.find_by(id: session[:omniauth_user_id])

    if @user.nil?
      redirect_to signup_path, alert: "Session expired. Please sign in again."
    end
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    # Check if this is an OAuth user completing their profile
    if session[:omniauth_user_id]
      @user = User.find_by(id: session[:omniauth_user_id])
      if @user
        # Update only the additional required fields
        @user.current_country = user_params[:current_country]

        respond_to do |format|
          if @user.save
            session.delete(:omniauth_user_id)
            log_in @user
            format.html { redirect_to travel_plans_path, notice: "Welcome! Your account was successfully created." }
            format.json { render :show, status: :created, location: @user }
          else
            format.html { render :complete_profile, status: :unprocessable_entity }
            format.json { render json: @user.errors, status: :unprocessable_entity }
          end
        end
        return
      end
    end

    # Regular signup flow
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

  def change_password
    # Renders app/views/users/change_password.html.erb
  end

  def verify_password
    # Protect OAuth users
    if @user.provider.present?
      render json: { valid: false }, status: :forbidden
      return
    end

    current_pwd = params[:current_password].to_s
    valid = @user.authenticate(current_pwd) if current_pwd.present?
    render json: { valid: !!valid }
  end

  def update_password
    # Prevent OAuth users from changing password
    if @user.provider.present?
      redirect_to user_path(@user), alert: "Password cannot be changed for accounts created via OAuth."
      return
    end

    # Ensure current password matches
    unless @user.authenticate(params[:current_password].to_s)
      @user.errors.add(:current_password, "is incorrect")
      render :change_password, status: :unprocessable_entity
      return
    end

    # Check if new password is the same as current password
    if @user.authenticate(params[:password].to_s)
      @user.errors.add(:password, "cannot be the same as your current password")
      render :change_password, status: :unprocessable_entity
      return
    end

    # Attempt to update new password fields
    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to user_path(@user), notice: "Password updated successfully."
    else
      render :change_password, status: :unprocessable_entity
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :passport_country, :current_country, :subscription_tier, :terms_accepted)
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
