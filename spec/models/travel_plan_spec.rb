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
  end
end
