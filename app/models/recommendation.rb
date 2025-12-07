class Recommendation < ApplicationRecord
  belongs_to :user
  belongs_to :destination

  validates :recommendation_score, presence: true, inclusion: { in: 0.0..10.0 }

  scope :high_rated, -> { where("recommendation_score >= ?", 7.0) }
  scope :recent, -> { order(created_at: :desc) }
end
