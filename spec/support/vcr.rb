# spec/support/vcr.rb
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.ignore_localhost = true
  
  # Allow HTTP connections when no cassette is in use (for tests without :vcr tag)
  config.allow_http_connections_when_no_cassette = true
  
  # Ignore geocoding requests in tests
  config.ignore_hosts 'maps.googleapis.com'
  
  # Filter sensitive data
  config.filter_sensitive_data('<RAPIDAPI_KEY>') { ENV['RAPIDAPI_KEY'] }
  config.filter_sensitive_data('<OPENAI_API_KEY>') { ENV['OPENAI_API_KEY'] }
end
