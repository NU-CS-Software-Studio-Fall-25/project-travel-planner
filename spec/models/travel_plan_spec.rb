# spec/models/travel_plan_spec.rb
require 'rails_helper'

RSpec.describe TravelPlan, type: :model do
  # Test associations
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:destination).optional }
  end

  # Test validations
  describe 'validations' do
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_length_of(:notes).is_at_most(1000) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(2000) }

    describe 'status validation' do
      it 'accepts valid statuses' do
        %w[planned booked completed cancelled].each do |status|
          plan = build(:travel_plan, status: status)
          expect(plan).to be_valid
        end
      end

      it 'rejects invalid statuses' do
        plan = build(:travel_plan, status: 'invalid')
        expect(plan).not_to be_valid
      end
    end

    describe 'date validation' do
      it 'is invalid when end_date is before start_date' do
        plan = build(:travel_plan, start_date: Date.today, end_date: Date.yesterday)
        expect(plan).not_to be_valid
        expect(plan.errors[:end_date]).to be_present
      end

      it 'is valid when end_date is after start_date' do
        plan = build(:travel_plan, start_date: Date.today, end_date: Date.tomorrow)
        expect(plan).to be_valid
      end

      it 'is valid when end_date equals start_date' do
        plan = build(:travel_plan, start_date: Date.today, end_date: Date.today)
        expect(plan).to be_valid
      end
    end
  end

  # Test itinerary serialization
  describe 'itinerary serialization' do
    let(:travel_plan) { create(:travel_plan) }

    it 'serializes Hash to JSON string' do
      itinerary_hash = { 'day_1' => 'Visit museum', 'day_2' => 'Beach day' }
      travel_plan.itinerary = itinerary_hash
      travel_plan.save!
      
      expect(travel_plan.reload.itinerary).to eq(itinerary_hash)
    end

    it 'deserializes JSON string to Hash' do
      json_string = '{"day_1":"Hiking","day_2":"Shopping"}'
      travel_plan.update_column(:itinerary, json_string)
      
      expect(travel_plan.reload.itinerary).to be_a(Hash)
      expect(travel_plan.itinerary['day_1']).to eq('Hiking')
    end

    it 'handles nil itinerary' do
      travel_plan.itinerary = nil
      travel_plan.save!
      
      expect(travel_plan.reload.itinerary).to be_nil
    end

    it 'handles Ruby hash syntax' do
      ruby_hash_string = '{"day_1" => "Activity 1", "day_2" => "Activity 2"}'
      travel_plan.update_column(:itinerary, ruby_hash_string)
      
      result = travel_plan.reload.itinerary
      expect(result).to be_a(Hash)
    end
  end

  # Test scopes and queries
  describe 'status filtering' do
    let!(:planned_trip) { create(:travel_plan, status: 'planned') }
    let!(:booked_trip) { create(:travel_plan, :booked) }
    let!(:completed_trip) { create(:travel_plan, :completed) }
    let!(:cancelled_trip) { create(:travel_plan, :cancelled) }

    it 'filters by status correctly' do
      expect(TravelPlan.where(status: 'planned')).to include(planned_trip)
      expect(TravelPlan.where(status: 'booked')).to include(booked_trip)
      expect(TravelPlan.where(status: 'completed')).to include(completed_trip)
    end
  end
end
