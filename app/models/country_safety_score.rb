class CountrySafetyScore < ApplicationRecord
  validates :country_name, presence: true
  validates :gpi_score, presence: true, numericality: { greater_than: 0 }
  validates :gpi_rank, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :year, presence: true
  validates :country_name, uniqueness: { scope: :year }
  
  # Safety level scopes based on mixed approach (percentile + actual safety meaning)
  # Very Safe: Top-tier safety, among the most peaceful countries (GPI < 1.6, Rank 1-27)
  scope :very_safe, -> { where("gpi_score < ?", 1.6) }
  
  # Generally Safe: Safe for travel with standard precautions (GPI 1.6-2.15, Rank ~28-104)
  scope :generally_safe, -> { where("gpi_score >= ? AND gpi_score < ?", 1.6, 2.15) }
  
  # Partly Safe: Moderate safety, requires awareness (GPI 2.15-2.7, Rank ~105-136)
  scope :partly_safe, -> { where("gpi_score >= ? AND gpi_score < ?", 2.15, 2.7) }
  
  # Not Safe: Higher risk destinations (GPI >= 2.7, Rank ~137-163)
  scope :not_safe, -> { where("gpi_score >= ?", 2.7) }
  
  # Get countries for a specific safety level
  def self.for_safety_level(level)
    case level
    when "Very Safe"
      very_safe
    when "Generally Safe"
      generally_safe
    when "Partly Safe"
      partly_safe
    when "Not Safe"
      not_safe
    else
      all
    end
  end
  
  # Get the safety level category for this country
  def safety_level
    case gpi_score
    when 0...1.6
      "Very Safe"
    when 1.6...2.15
      "Generally Safe"
    when 2.15...2.7
      "Partly Safe"
    else
      "Not Safe"
    end
  end
  
  # Get badge color for display
  def badge_color
    case gpi_score
    when 0...1.6
      "success"  # Green
    when 1.6...2.15
      "info"     # Blue
    when 2.15...2.7
      "warning"  # Yellow
    else
      "danger"   # Red
    end
  end
  
  # Human-readable description
  def safety_description
    case safety_level
    when "Very Safe"
      "Top-tier safety, among the most peaceful countries globally"
    when "Generally Safe"
      "Safe for travel with standard precautions"
    when "Partly Safe"
      "Moderate safety, requires awareness and caution"
    when "Not Safe"
      "Higher risk destination, for experienced travelers only"
    end
  end
end
