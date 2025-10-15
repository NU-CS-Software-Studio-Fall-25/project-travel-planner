class Destination < ApplicationRecord
  has_many :travel_plans, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :users, through: :travel_plans
  
  validates :name, presence: true
  validates :country, presence: true
  validates :safety_score, inclusion: { in: 1..10 }, allow_nil: true
  
  scope :safe_destinations, ->(min_safety) { where('safety_score >= ?', min_safety) }
  scope :visa_not_required, -> { where(visa_required: false) }
  scope :by_season, ->(season) { where(best_season: season) }
end
