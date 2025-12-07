class Destination < ApplicationRecord
  has_many :travel_plans, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :users, through: :travel_plans

  validates :name, presence: true, length: { maximum: 255 }
  validates :country, presence: true, length: { maximum: 100 }
  validates :city, length: { maximum: 255 }, allow_blank: true
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validates :safety_score, inclusion: { in: 1..10 }, allow_nil: true
  # latitude/longitude will be populated via geocoding if missing
  # Don't validate presence since geocoding might fail and we don't want to block destination creation
  validate :sanitize_text_fields

  # Use Geocoder to derive coordinates from name + country when missing
  geocoded_by :geocoding_address
  before_validation :geocode_if_needed
  after_validation :verify_geocoding_result

  def geocoding_address
    # Prioritize city + country for better geocoding accuracy
    # The city field should ideally include state/province for ambiguous names
    # e.g., "Burlington, Vermont" instead of just "Burlington"
    # Fall back to name + country if city is not available
    if city.present?
      [ city, country ].compact.join(", ")
    else
      [ name, country ].compact.join(", ")
    end
  end

  def full_address
    # For display purposes - show all available location info
    [ city, name, country ].compact.uniq.join(", ")
  end

  def geocode_if_needed
    if (latitude.blank? || longitude.blank?) && geocoding_address.present?
      result = geocode

      # Log geocoding attempts for debugging
      if result
        Rails.logger.info "Geocoded '#{geocoding_address}' to: #{latitude}, #{longitude}"
      else
        Rails.logger.warn "Failed to geocode '#{geocoding_address}'"
      end
    end
  end

  def verify_geocoding_result
    # After geocoding, verify that the coordinates make sense
    # This helps catch cases where geocoding returned unexpected results
    if latitude.present? && longitude.present?
      # Check if coordinates are in valid range
      unless latitude.between?(-90, 90) && longitude.between?(-180, 180)
        Rails.logger.error "Invalid coordinates for #{name}: #{latitude}, #{longitude}"
        self.latitude = nil
        self.longitude = nil
      end
    end
  end

  scope :safe_destinations, ->(min_safety) { where("safety_score >= ?", min_safety) }
  scope :visa_not_required, -> { where(visa_required: false) }
  scope :by_season, ->(season) { where(best_season: season) }

  private

  def sanitize_text_fields
    # Strip any potentially malicious HTML/JavaScript from text fields
    self.name = ActionController::Base.helpers.sanitize(name) if name.present?
    self.city = ActionController::Base.helpers.sanitize(city) if city.present?
    self.country = ActionController::Base.helpers.sanitize(country) if country.present?
    self.description = ActionController::Base.helpers.sanitize(description) if description.present?
  end
end
