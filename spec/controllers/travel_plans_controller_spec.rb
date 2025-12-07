# spec/controllers/travel_plans_controller_spec.rb
require 'rails_helper'

RSpec.describe TravelPlansController, type: :controller do
  let(:user) { create(:user, terms_accepted: true) }
  let(:destination) { create(:destination) }
  # The travel_plan factory was likely inheriting `terms_accepted` from the user factory.
  # Explicitly defining the user association prevents this.
  let(:travel_plan) { create(:travel_plan, user: user, destination: destination) }

  let(:valid_attributes) do
    {
      name: 'Summer Vacation',
      description: 'Beach trip',
      start_date: 1.week.from_now,
      end_date: 2.weeks.from_now,
      destination_id: destination.id,
      status: 'planned'
      # Removed 'budget' as it's not in travel_plan_params
    }
  end

  let(:invalid_attributes) do
    {
      name: nil, # A travel plan must have a name to be invalid in a way the model would reject
      start_date: Date.today,
      end_date: Date.yesterday,
      destination_id: destination.id
    }
  end

  before do
    # Mock the login helper
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'shows only current user travel plans' do
      other_user = create(:user, terms_accepted: true)
      other_plan = create(:travel_plan, user: other_user)
      my_plan = create(:travel_plan, user: user)

      get :index
      expect(assigns(:travel_plans)).to include(my_plan)
      expect(assigns(:travel_plans)).not_to include(other_plan)
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: travel_plan.to_param }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new TravelPlan' do
        expect {
          post :create, params: { travel_plan: valid_attributes }
        }.to change(TravelPlan, :count).by(1)
      end

      it 'assigns the travel plan to current user' do
        post :create, params: { travel_plan: valid_attributes }
        expect(TravelPlan.last.user).to eq(user)
      end

      it 'redirects to the created travel plan' do
        post :create, params: { travel_plan: valid_attributes }
        expect(response).to redirect_to(TravelPlan.last)
      end
    end

    context 'with invalid params' do
      it 'does not create a new TravelPlan' do
        expect {
          post :create, params: { travel_plan: invalid_attributes }
        }.not_to change(TravelPlan, :count)
      end

      it 'returns unprocessable entity status' do
        post :create, params: { travel_plan: invalid_attributes, format: :html }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Updated Vacation', status: 'booked' }
      end

      it 'updates the travel plan' do
        put :update, params: { id: travel_plan.to_param, travel_plan: new_attributes }
        travel_plan.reload
        expect(travel_plan.name).to eq('Updated Vacation')
        expect(travel_plan.status).to eq('booked')
      end

      it 'redirects to the travel plan' do
        put :update, params: { id: travel_plan.to_param, travel_plan: new_attributes }
        expect(response).to redirect_to(travel_plan)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:plan_to_delete) { create(:travel_plan, user: user) }

    it 'destroys the travel plan' do
      expect {
        delete :destroy, params: { id: plan_to_delete.to_param }
      }.to change(TravelPlan, :count).by(-1)
    end

    it 'redirects to the travel plans list' do
      delete :destroy, params: { id: plan_to_delete.to_param }
      expect(response).to redirect_to(travel_plans_url)
    end
  end

  describe 'status transitions' do
    it 'can update from planned to booked' do
      planned_trip = create(:travel_plan, user: user, status: 'planned')
      put :update, params: { id: planned_trip.to_param, travel_plan: { status: 'booked' } }
      expect(planned_trip.reload.status).to eq('booked')
    end

    it 'can mark trip as completed' do
      booked_trip = create(:travel_plan, user: user, status: 'booked')
      put :update, params: { id: booked_trip.to_param, travel_plan: { status: 'completed' } }
      expect(booked_trip.reload.status).to eq('completed')
    end

    it 'can cancel a trip' do
      planned_trip = create(:travel_plan, user: user, status: 'planned')
      put :update, params: { id: planned_trip.to_param, travel_plan: { status: 'cancelled' } }
      expect(planned_trip.reload.status).to eq('cancelled')
    end
  end
end
