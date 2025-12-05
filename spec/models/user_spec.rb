# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  # Test validations
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(50) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:current_country) }

    context 'password validation for non-OAuth users' do
      it 'validates password format for new users' do
        user = build(:user, password: 'weak')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include(/must be at least 7 characters/)
      end

      it 'accepts valid password' do
        user = build(:user, password: 'Password1!', password_confirmation: 'Password1!')
        expect(user).to be_valid
      end

      it 'does not validate password for OAuth users' do
        user = build(:user, :oauth_user)
        expect(user).to be_valid
      end
    end
  end

  # Test associations
  describe 'associations' do
    it { should have_many(:travel_plans).dependent(:destroy) }
    it { should have_many(:recommendations).dependent(:destroy) }
    it { should have_many(:destinations).through(:travel_plans) }
    it { should have_many(:recommendation_feedbacks).dependent(:destroy) }
  end

  # Test generation limit feature
  describe 'recommendation generation limits' do
    let(:free_user) { create(:user) }
    let(:premium_user) { create(:user, :premium) }

    describe '#can_generate_recommendation?' do
      it 'returns true for premium users regardless of usage' do
        premium_user.update_column(:recommendation_generations_used, 100)
        expect(premium_user.can_generate_recommendation?).to be true
      end

      it 'returns true for free users under the limit' do
        free_user.update_column(:recommendation_generations_used, 5)
        expect(free_user.can_generate_recommendation?).to be true
      end

      it 'returns false for free users at the limit' do
        free_user.update_column(:recommendation_generations_used, User::FREE_TIER_GENERATION_LIMIT)
        expect(free_user.can_generate_recommendation?).to be false
      end

      it 'resets count after a month' do
        free_user.update_columns(
          recommendation_generations_used: User::FREE_TIER_GENERATION_LIMIT,
          generations_reset_at: 2.months.ago
        )
        expect(free_user.can_generate_recommendation?).to be true
      end
    end

    describe '#increment_generations_used!' do
      it 'increments the counter for free users' do
        expect {
          free_user.increment_generations_used!
        }.to change { free_user.reload.recommendation_generations_used }.by(1)
      end

      it 'does not increment for premium users' do
        expect {
          premium_user.increment_generations_used!
        }.not_to change { premium_user.reload.recommendation_generations_used }
      end

      it 'handles nil values correctly' do
        free_user.update_column(:recommendation_generations_used, nil)
        free_user.increment_generations_used!
        expect(free_user.reload.recommendation_generations_used).to eq(1)
      end
    end

    describe '#remaining_generations' do
      it 'returns infinity for premium users' do
        expect(premium_user.remaining_generations).to eq(Float::INFINITY)
      end

      it 'calculates remaining generations for free users' do
        free_user.update_column(:recommendation_generations_used, 10)
        expected = User::FREE_TIER_GENERATION_LIMIT - 10
        expect(free_user.remaining_generations).to eq(expected)
      end

      it 'returns 0 when at limit' do
        free_user.update_column(:recommendation_generations_used, User::FREE_TIER_GENERATION_LIMIT)
        expect(free_user.remaining_generations).to eq(0)
      end
    end
  end

  # Test OAuth functionality
  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '123456',
        info: {
          email: 'oauth@example.com',
          name: 'OAuth User',
          email_verified: true
        },
        credentials: {
          token: 'oauth_token_123',
          expires_at: 1.hour.from_now.to_i
        }
      })
    end

    it 'creates a new user from OAuth data' do
      expect {
        User.from_omniauth(auth)
      }.to change { User.count }.by(1)
    end

    it 'sets correct attributes from OAuth' do
      user = User.from_omniauth(auth)
      expect(user.provider).to eq('google_oauth2')
      expect(user.uid).to eq('123456')
      expect(user.email).to eq('oauth@example.com')
      expect(user.name).to eq('OAuth User')
      expect(user.email_verified).to be true
    end

    it 'updates existing user on subsequent logins' do
      user = User.from_omniauth(auth)
      auth.info.name = 'Updated Name'
      
      updated_user = User.from_omniauth(auth)
      expect(updated_user.id).to eq(user.id)
      expect(updated_user.name).to eq('Updated Name')
    end

    it 'sets default current_country if not present' do
      user = User.from_omniauth(auth)
      expect(user.current_country).to eq('United States')
    end
  end

  describe '#oauth_user?' do
    it 'returns true for OAuth users' do
      user = build(:user, :oauth_user)
      expect(user.oauth_user?).to be true
    end

    it 'returns false for regular users' do
      user = build(:user)
      expect(user.oauth_user?).to be false
    end
  end

  describe '#premium?' do
    let(:premium_user) { create(:user, :premium) }
    let(:free_user) { create(:user) }

    it 'returns true for premium users' do
      expect(premium_user.premium?).to be true
    end

    it 'returns false for free users' do
      expect(free_user.premium?).to be false
    end
  end
end
