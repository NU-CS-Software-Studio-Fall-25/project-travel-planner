# spec/models/destination_spec.rb
require 'rails_helper'

RSpec.describe Destination, type: :model do
  # Test validations
  describe 'validations' do
    subject { build(:destination) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:country) }

    it 'allows blank city' do
      destination = build(:destination, city: '')
      expect(destination).to be_valid
    end
  end

  # Test associations
  describe 'associations' do
    it { should have_many(:travel_plans) }
    it { should have_many(:users).through(:travel_plans) }
  end

  # Test scopes and queries
  describe 'country filtering' do
    let!(:us_destination) { create(:destination, :domestic, country: 'United States') }
    let!(:france_destination) { create(:destination, country: 'France') }
    let!(:japan_destination) { create(:destination, country: 'Japan') }

    it 'filters destinations by country' do
      us_destinations = Destination.where(country: 'United States')
      expect(us_destinations).to include(us_destination)
      expect(us_destinations).not_to include(france_destination)
    end

    it 'orders destinations by name' do
      destinations = Destination.order(:name).to_a
      expect(destinations.map(&:name)).to eq(destinations.map(&:name).sort)
    end
  end

  describe 'safety score' do
    it 'can be set to a safe score' do
      destination = create(:destination, :safe)
      expect(destination.safety_score).to eq(2)
    end

    it 'can be set to an unsafe score' do
      destination = create(:destination, :unsafe)
      expect(destination.safety_score).to eq(8)
    end
  end
end
