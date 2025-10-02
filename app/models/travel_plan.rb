class TravelPlan < ApplicationRecord
  belongs_to :user
  belongs_to :destination
  
  validates :start_date, :end_date, presence: true
  validates :status, inclusion: { in: %w[planned booked completed cancelled] }
  validate :end_date_after_start_date
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
