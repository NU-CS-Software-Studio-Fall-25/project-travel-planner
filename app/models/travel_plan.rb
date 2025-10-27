class TravelPlan < ApplicationRecord
  belongs_to :user
  belongs_to :destination
  
  # Serialize JSON fields for itinerary and budget_breakdown
  serialize :itinerary, coder: JSON
  serialize :budget_breakdown, coder: JSON
  
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
