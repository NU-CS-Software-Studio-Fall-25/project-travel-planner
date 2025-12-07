# app/models/recommendation_feedback.rb

class RecommendationFeedback < ApplicationRecord
  belongs_to :user

  # Validations
  validates :destination_city, presence: true, length: { maximum: 100 }
  validates :destination_country, presence: true, length: { maximum: 100 }
  validates :feedback_type, presence: true, inclusion: { in: %w[like dislike] }
  validates :reason, length: { maximum: 500 }, allow_blank: true
  validates :trip_type, length: { maximum: 50 }, allow_blank: true
  validates :travel_style, length: { maximum: 50 }, allow_blank: true

  # Ensure user can only have one feedback per destination
  validates :destination_city, uniqueness: {
    scope: [ :user_id, :destination_country ],
    message: "already has feedback from this user"
  }

  # Scopes
  scope :likes, -> { where(feedback_type: "like") }
  scope :dislikes, -> { where(feedback_type: "dislike") }
  scope :recent, -> { order(created_at: :desc) }

  # Class methods for learning
  def self.user_preferences(user_id)
    # Use parameterized queries to prevent SQL injection
    sanitized_user_id = user_id.to_i

    # Return empty structure if invalid user_id
    return {
      liked_destinations: [],
      disliked_destinations: [],
      preferred_styles: [],
      avoided_styles: []
    } if sanitized_user_id <= 0

    liked = likes.where(user_id: sanitized_user_id)
    disliked = dislikes.where(user_id: sanitized_user_id)

    {
      liked_destinations: liked.map { |f|
        {
          city: f.destination_city.to_s.strip,
          country: f.destination_country.to_s.strip,
          travel_style: f.travel_style.to_s.strip,
          trip_type: f.trip_type.to_s.strip,
          length_of_stay: f.length_of_stay.to_i
        }
      },
      disliked_destinations: disliked.map { |f|
        {
          city: f.destination_city.to_s.strip,
          country: f.destination_country.to_s.strip,
          travel_style: f.travel_style.to_s.strip,
          trip_type: f.trip_type.to_s.strip,
          length_of_stay: f.length_of_stay.to_i
        }
      },
      preferred_styles: liked.where.not(travel_style: [ nil, "" ]).pluck(:travel_style).uniq.map(&:strip),
      avoided_styles: disliked.where.not(travel_style: [ nil, "" ]).pluck(:travel_style).uniq.map(&:strip)
    }
  end
end
