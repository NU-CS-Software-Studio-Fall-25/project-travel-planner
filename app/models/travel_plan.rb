class TravelPlan < ApplicationRecord
  include ProfanityFilterable
  
  belongs_to :user
  belongs_to :destination, optional: true
  has_many :content_reports, as: :reportable, dependent: :destroy
  
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
  validates :notes, length: { maximum: 1000 }, allow_blank: true
  validates :name, length: { maximum: 255 }, allow_blank: true
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validate :end_date_after_start_date
  validate :sanitize_text_fields
  validate :budget_max_greater_than_or_equal_to_min
  
  # Profanity validation
  validates_profanity_of :notes, :name, :description
  
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
  
  def sanitize_text_fields
    # Strip any potentially malicious HTML/JavaScript from text fields
    self.notes = ActionController::Base.helpers.sanitize(notes) if notes.present?
    self.name = ActionController::Base.helpers.sanitize(name) if name.present?
    self.description = ActionController::Base.helpers.sanitize(description) if description.present?
  end
  
  def budget_max_greater_than_or_equal_to_min
    return unless budget_min.present? && budget_max.present?
    
    if budget_max < budget_min
      errors.add(:budget_max, "must be greater than or equal to minimum budget")
    end
  end
end
