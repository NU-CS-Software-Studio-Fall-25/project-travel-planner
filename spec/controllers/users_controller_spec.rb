# spec/controllers/users_controller_spec.rb
require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:valid_attributes) do
    {
      name: 'John Doe',
      email: 'john@example.com',
      password: 'Password1!',
      password_confirmation: 'Password1!',
      current_country: 'United States'
    }
  end

  let(:invalid_attributes) do
    {
      name: '',
      email: 'invalid',
      password: 'weak',
      current_country: ''
    }
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new User' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'logs in the new user' do
        post :create, params: { user: valid_attributes }
        expect(session[:user_id]).to eq(User.last.id)
      end

      it 'redirects to travel plans path' do
        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(travel_plans_path)
      end

      it 'sets welcome flash message' do
        post :create, params: { user: valid_attributes }
        expect(flash[:notice]).to match(/Welcome/)
      end

      it 'downcases email before saving' do
        attrs = valid_attributes.merge(email: 'UPPER@EXAMPLE.COM')
        post :create, params: { user: attrs }
        expect(User.last.email).to eq('upper@example.com')
      end
    end

    context 'with invalid params' do
      it 'does not create a new User' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end

      it 'returns unprocessable entity status' do
        post :create, params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not set session user_id' do
        post :create, params: { user: invalid_attributes }
        expect(session[:user_id]).to be_nil
      end
    end

    context 'password validation' do
      it 'requires uppercase letter' do
        attrs = valid_attributes.merge(password: 'password1!', password_confirmation: 'password1!')
        post :create, params: { user: attrs }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'requires lowercase letter' do
        attrs = valid_attributes.merge(password: 'PASSWORD1!', password_confirmation: 'PASSWORD1!')
        post :create, params: { user: attrs }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'requires digit' do
        attrs = valid_attributes.merge(password: 'Password!', password_confirmation: 'Password!')
        post :create, params: { user: attrs }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'requires special character' do
        attrs = valid_attributes.merge(password: 'Password1', password_confirmation: 'Password1')
        post :create, params: { user: attrs }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'requires minimum length' do
        attrs = valid_attributes.merge(password: 'Pass1!', password_confirmation: 'Pass1!')
        post :create, params: { user: attrs }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #show' do
    let(:user) { create(:user) }

    context 'when logged in as the user' do
      before { log_in_as(user) }

      it 'returns a success response' do
        get :show, params: { id: user.to_param }
        expect(response).to be_successful
      end

      it 'assigns the user' do
        get :show, params: { id: user.to_param }
        expect(assigns(:user)).to eq(user)
      end
    end
  end
end
