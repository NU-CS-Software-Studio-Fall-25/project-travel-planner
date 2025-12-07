# spec/models/recommendation_feedback_spec.rb
require 'rails_helper'

RSpec.describe RecommendationFeedback, type: :model do
  # Test associations
  describe 'associations' do
    it { should belong_to(:user) }
  end

  # Test validations
  describe 'validations' do
    subject { build(:recommendation_feedback) }

    it { should validate_presence_of(:destination_city) }
    it { should validate_presence_of(:destination_country) }
    it { should validate_presence_of(:feedback_type) }
    it { should validate_length_of(:destination_city).is_at_most(100) }
    it { should validate_length_of(:destination_country).is_at_most(100) }
    it { should validate_length_of(:reason).is_at_most(500) }
    it { should validate_length_of(:trip_type).is_at_most(50) }
    it { should validate_length_of(:travel_style).is_at_most(50) }

    describe 'feedback_type validation' do
      it 'accepts like' do
        feedback = build(:recommendation_feedback, feedback_type: 'like')
        expect(feedback).to be_valid
      end

      it 'accepts dislike' do
        feedback = build(:recommendation_feedback, feedback_type: 'dislike')
        expect(feedback).to be_valid
      end

      it 'rejects invalid feedback types' do
        feedback = build(:recommendation_feedback, feedback_type: 'maybe')
        expect(feedback).not_to be_valid
      end
    end

    describe 'uniqueness validation' do
      let(:user) { create(:user, terms_accepted: true) }

      it 'prevents duplicate feedback for same destination by same user' do
        create(:recommendation_feedback,
               user: user,
               destination_city: 'Paris',
               destination_country: 'France')

        duplicate = build(:recommendation_feedback,
                          user: user,
                          destination_city: 'Paris',
                          destination_country: 'France')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:destination_city]).to be_present
      end

      it 'allows same destination feedback from different users' do
        user2 = create(:user, terms_accepted: true)
        create(:recommendation_feedback,
               user: user,
               destination_city: 'Paris',
               destination_country: 'France')

        feedback2 = build(:recommendation_feedback,
                          user: user2,
                          destination_city: 'Paris',
                          destination_country: 'France')

        expect(feedback2).to be_valid
      end
    end
  end

  # Test scopes
  describe 'scopes' do
    let(:user) { create(:user, terms_accepted: true) }
    let!(:like_feedback) { create(:recommendation_feedback, user: user, feedback_type: 'like', destination_city: 'Kyoto') }
    let!(:dislike_feedback) { create(:recommendation_feedback, :dislike, user: user, destination_city: 'Cancun') }
    let!(:old_feedback) { create(:recommendation_feedback, user: user, created_at: 1.month.ago, destination_city: 'Rome') }

    describe '.likes' do
      it 'returns only like feedbacks' do
        expect(RecommendationFeedback.likes).to include(like_feedback)
        expect(RecommendationFeedback.likes).not_to include(dislike_feedback)
      end
    end

    describe '.dislikes' do
      it 'returns only dislike feedbacks' do
        expect(RecommendationFeedback.dislikes).to include(dislike_feedback)
        expect(RecommendationFeedback.dislikes).not_to include(like_feedback)
      end
    end

    describe '.recent' do
      it 'orders by created_at descending' do
        # Re-fetch to ensure order
        recent_feedbacks = RecommendationFeedback.recent.to_a
        expect(recent_feedbacks.first.created_at).to be > recent_feedbacks.last.created_at
      end
    end
  end

  # Test class methods
  describe '.user_preferences' do
    let(:user) { create(:user, terms_accepted: true) }

    before do
      create(:recommendation_feedback,
             user: user,
             feedback_type: 'like',
             destination_city: 'Tokyo',
             destination_country: 'Japan',
             travel_style: 'cultural',
             trip_type: 'leisure',
             length_of_stay: 7)

      create(:recommendation_feedback,
             user: user,
             feedback_type: 'dislike',
             destination_city: 'Las Vegas',
             destination_country: 'USA',
             travel_style: 'party',
             trip_type: 'weekend',
             length_of_stay: 2)
    end

    it 'returns user preferences structure' do
      preferences = RecommendationFeedback.user_preferences(user.id)

      expect(preferences).to have_key(:liked_destinations)
      expect(preferences).to have_key(:disliked_destinations)
      expect(preferences).to have_key(:preferred_styles)
      expect(preferences).to have_key(:avoided_styles)
    end

    it 'includes liked destinations' do
      preferences = RecommendationFeedback.user_preferences(user.id)
      liked = preferences[:liked_destinations].first

      expect(liked[:city]).to eq('Tokyo')
      expect(liked[:country]).to eq('Japan')
      expect(liked[:travel_style]).to eq('cultural')
    end

    it 'includes disliked destinations' do
      preferences = RecommendationFeedback.user_preferences(user.id)
      disliked = preferences[:disliked_destinations].first

      expect(disliked[:city]).to eq('Las Vegas')
      expect(disliked[:country]).to eq('USA')
    end

    it 'handles invalid user_id' do
      preferences = RecommendationFeedback.user_preferences(-1)

      expect(preferences[:liked_destinations]).to be_empty
      expect(preferences[:disliked_destinations]).to be_empty
    end

    it 'prevents SQL injection' do
      expect {
        RecommendationFeedback.user_preferences("1 OR 1=1")
      }.not_to raise_error
    end
  end
end
