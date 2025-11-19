# app/models/user.rb
class User < ApplicationRecord
  has_secure_password validations: false

  has_many :travel_plans, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :destinations, through: :travel_plans
  has_many :recommendation_feedbacks, dependent: :destroy

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

  before_save { self.email = email.downcase }

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
end
