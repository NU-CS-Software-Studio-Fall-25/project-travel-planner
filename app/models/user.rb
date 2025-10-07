class User < ApplicationRecord
  has_secure_password
  
  has_many :travel_plans, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :destinations, through: :travel_plans
  
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :passport_country, presence: true
  validates :safety_preference, inclusion: { in: 1..10 }
  validates :budget_min, presence: true, numericality: { greater_than: 0 }
  validates :budget_max, presence: true, numericality: { greater_than: :budget_min }
  validates :preferred_travel_season, presence: true, 
            inclusion: { in: %w[Spring Summer Fall Winter] }
  
  before_save { self.email = email.downcase }
end
