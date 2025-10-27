class Destination < ApplicationRecord
  has_many :travel_plans, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :users, through: :travel_plans
  
  validates :name, presence: true
  validates :country, presence: true
  validates :safety_score, inclusion: { in: 1..10 }
  # latitude/longitude will be populated via geocoding if missing
  validates :latitude, :longitude, presence: true, unless: -> { latitude.blank? && longitude.blank? }

  # Use Geocoder to derive coordinates from name + country when missing
  geocoded_by :full_address
  before_validation :geocode_if_needed

  def full_address
    [name, country].compact.join(', ')
  end

  def geocode_if_needed
    if (latitude.blank? || longitude.blank?) && full_address.present?
      geocode
    end
  end
  
  scope :safe_destinations, ->(min_safety) { where('safety_score >= ?', min_safety) }
  scope :visa_not_required, -> { where(visa_required: false) }
  scope :by_season, ->(season) { where(best_season: season) }
end
