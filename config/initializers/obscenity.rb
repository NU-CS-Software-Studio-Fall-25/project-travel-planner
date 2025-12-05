# config/initializers/obscenity.rb
require 'obscenity/active_model'

# Configure Obscenity profanity filter
Obscenity.configure do |config|
  # Use the default blacklist
  config.blacklist = Obscenity::Base.blacklist
  
  # Add custom words to the blacklist if needed
  # config.blacklist.add(%w[customword1 customword2])
  
  # Set replacement character for profane words
  config.replacement = :stars # Options: :garbled, :stars, :vowels, or custom string
end
