# app/models/concerns/profanity_filterable.rb
module ProfanityFilterable
  extend ActiveSupport::Concern

  class_methods do
    # Add profanity validation to specified attributes
    def validates_profanity_of(*attributes)
      attributes.each do |attribute|
        validate do
          value = send(attribute)
          if value.present? && Obscenity.profane?(value)
            errors.add(attribute, "contains inappropriate language. Please remove profanity.")
          end
        end
      end
    end

    # Sanitize profanity from specified attributes (replace with stars)
    def sanitizes_profanity_from(*attributes)
      attributes.each do |attribute|
        before_validation do
          value = send(attribute)
          if value.present? && Obscenity.profane?(value)
            send("#{attribute}=", Obscenity.sanitize(value))
          end
        end
      end
    end
  end
end
