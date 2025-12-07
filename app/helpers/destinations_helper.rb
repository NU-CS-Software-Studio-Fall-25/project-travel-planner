module DestinationsHelper
  # Generate a TripAdvisor URL for a destination
  def tripadvisor_url(destination)
    return nil unless destination&.name.present?

    # Public TripAdvisor homepage - users can search for the destination themselves
    "https://www.tripadvisor.com/"
  end

  # Return appropriate Bootstrap badge class based on safety score
  def safety_badge_class(score)
    return "bg-secondary" unless score.present?

    case score.to_i
    when 8..10
      "bg-success"
    when 5..7
      "bg-warning text-dark"
    when 0..4
      "bg-danger"
    else
      "bg-secondary"
    end
  end
end
