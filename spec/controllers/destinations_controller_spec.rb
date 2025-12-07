# spec/controllers/destinations_controller_spec.rb
require 'rails_helper'

RSpec.describe DestinationsController, type: :controller do
  let(:user) { create(:user, terms_accepted: true) }
  let(:destination) { create(:destination) }
  let(:valid_attributes) do
    {
      name: 'Paris',
      city: 'Paris',
      country: 'France',
      description: 'The City of Light',
      latitude: 48.8566,
      longitude: 2.3522
    }
  end
  let(:invalid_attributes) do
    {
      name: '',
      city: '',
      country: ''
    }
  end

  before do
    log_in_as(user)
  end

  describe 'GET #index' do
    context 'when user has current_country set' do
      let!(:domestic_dest) { create(:destination, country: user.current_country) }
      let!(:international_dest) { create(:destination, country: 'France') }

      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end
    end

    context 'when user has no current_country' do
      before do
        user.update_column(:current_country, nil)
        create(:destination)
      end

      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: destination.to_param }
      expect(response).to be_successful
    end

    it 'assigns the requested destination' do
      get :show, params: { id: destination.to_param }
      expect(assigns(:destination)).to eq(destination)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new destination' do
      get :new
      expect(assigns(:destination)).to be_a_new(Destination)
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: destination.to_param }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Destination' do
        expect {
          post :create, params: { destination: valid_attributes }
        }.to change(Destination, :count).by(1)
      end

      it 'redirects to the created destination' do
        post :create, params: { destination: valid_attributes }
        expect(response).to redirect_to(Destination.last)
      end

      it 'sets a flash notice' do
        post :create, params: { destination: valid_attributes }
        expect(flash[:notice]).to match(/successfully created/)
      end
    end

    context 'with invalid params' do
      it 'does not create a new Destination' do
        expect {
          post :create, params: { destination: invalid_attributes }
        }.not_to change(Destination, :count)
      end

      it 'returns unprocessable entity status' do
        post :create, params: { destination: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Updated Paris', description: 'An updated description' }
      end

      it 'updates the requested destination' do
        put :update, params: { id: destination.to_param, destination: new_attributes }
        destination.reload
        expect(destination.name).to eq('Updated Paris')
        expect(destination.description).to eq('An updated description')
      end

      it 'redirects to the destination' do
        put :update, params: { id: destination.to_param, destination: new_attributes }
        expect(response).to redirect_to(destination)
      end
    end

    context 'with invalid params' do
      it 'does not update the destination' do
        original_name = destination.name
        put :update, params: { id: destination.to_param, destination: invalid_attributes }
        destination.reload
        expect(destination.name).to eq(original_name)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:destination_to_delete) { create(:destination) }

    it 'destroys the requested destination' do
      expect {
        delete :destroy, params: { id: destination_to_delete.to_param }
      }.to change(Destination, :count).by(-1)
    end

    it 'redirects to the destinations list' do
      delete :destroy, params: { id: destination_to_delete.to_param }
      expect(response).to redirect_to(destinations_url)
    end
  end
end
