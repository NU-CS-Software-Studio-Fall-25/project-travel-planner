# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  has_many :travel_plans, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :destinations, through: :travel_plans

  # Serialize recommendations_json as JSON
  serialize :recommendations_json, coder: JSON

  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  before_save { self.email = email.downcase }

  # Helper methods for managing recommendations stored as JSON
  def cached_recommendations
    recommendations_json ? JSON.parse(recommendations_json) : []
  end

  def cache_recommendations(recommendations_array)
    update(recommendations_json: recommendations_array.to_json)
  end
end
