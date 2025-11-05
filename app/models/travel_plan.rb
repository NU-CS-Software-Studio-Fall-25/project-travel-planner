class TravelPlan < ApplicationRecord
  belongs_to :user
  belongs_to :destination
  
  # Custom serializer for itinerary that handles both JSON and Ruby hash formats
  class ItinerarySerializer
    def self.dump(obj)
      return nil if obj.nil?
      obj.is_a?(String) ? obj : JSON.generate(obj)
    end
    
    def self.load(value)
      return nil if value.nil? || value.empty?
      
      # If it's already a Hash, return it
      return value if value.is_a?(Hash)
      
      # Try to parse as JSON first
      begin
        return JSON.parse(value)
      rescue JSON::ParserError
        # Not JSON, continue to Ruby hash parsing
      end
      
      # Try to parse as Ruby hash literal (e.g., {"key" => "value"})
      begin
        # Only eval if it looks like a hash (starts with { and ends with })
        if value.strip.start_with?('{') && value.strip.end_with?('}')
          # Use eval with a clean binding to parse Ruby hash syntax
          result = eval(value)
          return result if result.is_a?(Hash)
        end
      rescue SyntaxError, StandardError => e
        Rails.logger.warn "Failed to parse itinerary: #{e.message}"
      end
      
      # If all parsing fails, return the raw string
      value
    end
  end
  
  serialize :itinerary, coder: ItinerarySerializer
  
  validates :start_date, :end_date, presence: true
  validates :status, inclusion: { in: %w[planned booked completed cancelled] }, allow_nil: true
  validate :end_date_after_start_date
  
  # Set default status
  before_validation :set_default_status, on: :create
  
  # Scope to get recent travel plans
  scope :recent, -> { order(created_at: :desc) }
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
  
  def set_default_status
    self.status ||= 'planned'
  end
end
