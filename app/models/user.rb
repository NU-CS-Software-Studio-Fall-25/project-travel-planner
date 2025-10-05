class User < ApplicationRecord
  has_many :travel_plans, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :destinations, through: :travel_plans
  
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :passport_country, presence: true
  validates :safety_preference, inclusion: { in: 1..10 }
end
