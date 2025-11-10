# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

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
  VALID_PASSWORD_REGEX = /\A(?=.{7,})(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@#\$%&!\*]).*\z/
  validates :password, format: { with: VALID_PASSWORD_REGEX, message: 'must be at least 7 characters and include one uppercase letter, one lowercase letter, one digit and one special character (@#$%&!*)' }, if: -> { new_record? || !password.nil? }
  validates :current_country, presence: true

  before_save { self.email = email.downcase }

  # Helper methods for managing recommendations stored as JSON
  def cached_recommendations
    recommendations_json ? JSON.parse(recommendations_json) : []
  end

  def cache_recommendations(recommendations_array)
    update(recommendations_json: recommendations_array.to_json)
  end
end
