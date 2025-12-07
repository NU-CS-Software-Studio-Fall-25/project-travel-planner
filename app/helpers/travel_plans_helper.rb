module TravelPlansHelper
  # Convert numeric safety_score to categorical safety_level
  def safety_score_to_level(score)
    return "level_1" if score.nil?

    case score
    when 8..10 then "level_1"
    when 6..7 then "level_2"
    when 3..5 then "level_3"
    when 0..2 then "level_4"
    else "level_1"
    end
  end

  # Get human-readable safety level text
  def safety_level_text(level)
    case level
    when "level_1" then "Level 1: Safe"
    when "level_2" then "Level 2: Moderate"
    when "level_3" then "Level 3: High Risk"
    when "level_4" then "Level 4: Extreme Risk"
    else "Unknown"
    end
  end

  # Get Bootstrap badge class for safety level
  def safety_level_badge_class(level)
    case level
    when "level_1" then "bg-success"
    when "level_2" then "bg-warning"
    when "level_3" then "bg-orange text-dark"
    when "level_4" then "bg-danger"
    else "bg-secondary"
    end
  end
end
