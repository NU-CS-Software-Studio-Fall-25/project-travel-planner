class ContentReport < ApplicationRecord
  include ProfanityFilterable
  
  belongs_to :user
  belongs_to :reportable, polymorphic: true
  belongs_to :reviewer, class_name: 'User', foreign_key: 'reviewed_by', optional: true
  
  # Report types
  REPORT_TYPES = %w[
    spam
    inappropriate_content
    harassment
    misinformation
    profanity
    other
  ].freeze
  
  # Report statuses
  STATUSES = %w[
    pending
    reviewing
    resolved
    dismissed
  ].freeze
  
  validates :reason, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :report_type, presence: true, inclusion: { in: REPORT_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates_profanity_of :reason
  
  # Prevent duplicate reports
  validates :user_id, uniqueness: { 
    scope: [:reportable_type, :reportable_id], 
    message: "has already reported this content" 
  }
  
  scope :pending, -> { where(status: 'pending') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :recent, -> { order(created_at: :desc) }
  
  def resolve!(reviewer_user, notes = nil)
    update!(
      status: 'resolved',
      reviewed_by: reviewer_user.id,
      reviewed_at: Time.current,
      resolution_notes: notes
    )
  end
  
  def dismiss!(reviewer_user, notes = nil)
    update!(
      status: 'dismissed',
      reviewed_by: reviewer_user.id,
      reviewed_at: Time.current,
      resolution_notes: notes
    )
  end
end
