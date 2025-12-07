# features/support/database_cleaner.rb
require 'database_cleaner/active_record'

# Use the faster transaction strategy for scenarios that don't require JavaScript.
DatabaseCleaner.strategy = :transaction

# Use the truncation strategy for scenarios tagged with @javascript,
# as transactions won't work with a separate server thread.
Before('@javascript') do
  DatabaseCleaner.strategy = :truncation
end

# Reset the strategy back to :transaction after the @javascript scenario completes.
After('@javascript') do
  DatabaseCleaner.strategy = :transaction
end

# These hooks will run for all scenarios
Before do
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
end
