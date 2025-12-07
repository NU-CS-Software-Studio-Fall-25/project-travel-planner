# app/models/user.rb
class User < ApplicationRecord
  has_secure_password validations: false
  FREE_TIER_GENERATION_LIMIT = 30
  has_many :travel_plans, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :destinations, through: :travel_plans
  has_many :recommendation_feedbacks, dependent: :destroy
  has_many :content_reports, dependent: :destroy

  # Serialize recommendations_json as JSON
  serialize :recommendations_json, coder: JSON

  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  # Password must be at least 7 chars and include uppercase, lowercase, digit and a special char
  # Only validate password for non-OAuth users (those without provider)
  VALID_PASSWORD_REGEX = /\A(?=.{7,})(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@#\$%&!\*]).*\z/
  validates :password, format: { with: VALID_PASSWORD_REGEX, message: 'must be at least 7 characters and include one uppercase letter, one lowercase letter, one digit and one special character (@#$%&!*)' }, if: -> { (new_record? || !password.nil?) && provider.blank? }
  validates :password, presence: true, if: -> { new_record? && provider.blank? }
  validates :current_country, presence: true
  validates :terms_accepted, acceptance: { message: "must be accepted" }, on: :create

  before_save { self.email = email.downcase }
  before_create :set_terms_accepted_at

  # Checks if the user can generate a new recommendation
  def can_generate_recommendation?
    return true if premium?

    reset_generation_count_if_needed!
    recommendation_generations_used < FREE_TIER_GENERATION_LIMIT
  end

  # Increments the generation counter
  def increment_generations_used!
    return if premium?

    reset_generation_count_if_needed!
    # ensure attribute isn't nil before incrementing
    self.recommendation_generations_used = (recommendation_generations_used || 0) + 1
    save!(validate: false)
  end

  # Returns the number of remaining generations for the current period
  def remaining_generations
    return Float::INFINITY if premium?

    reset_generation_count_if_needed!
    [ 0, FREE_TIER_GENERATION_LIMIT - (recommendation_generations_used || 0) ].max
  end

  def premium?
    subscription_tier == "premium"
  end

  # Helper methods for managing recommendations stored as JSON
  def cached_recommendations
    recommendations_json ? JSON.parse(recommendations_json) : []
  end

  def cache_recommendations(recommendations_array)
    update(recommendations_json: recommendations_array.to_json)
  end

  # OAuth authentication
  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    # Update user attributes from OAuth data
    user.email = auth.info.email
    user.name = auth.info.name
    user.oauth_token = auth.credentials.token
    user.oauth_expires_at = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at
    user.email_verified = true if auth.info.email_verified

    # Set a default current_country if not set (required field)
    user.current_country ||= "United States"

    # Save without password validation for OAuth users
    user.save(validate: false) if user.new_record?
    user.save if user.persisted?

    user
  end

  def oauth_user?
    provider.present?
  end

  def generate_password_reset_token!
    loop do
      self.reset_password_token = SecureRandom.urlsafe_base64(24)
      break unless self.class.exists?(reset_password_token: reset_password_token)
    end
    self.reset_password_sent_at = Time.current
    save!(validate: false)
  end

  private

  # Resets the monthly generation count if a month has passed
  def reset_generation_count_if_needed!
    if generations_reset_at.nil? || generations_reset_at < 1.month.ago
      # Persist reset and keep in-memory attributes in sync
      update_columns(recommendation_generations_used: 0, generations_reset_at: Time.current)
      self.recommendation_generations_used = 0
      self.generations_reset_at = Time.current
    end
  end

  def set_terms_accepted_at
    self.terms_accepted_at = Time.current if terms_accepted
  end
end
