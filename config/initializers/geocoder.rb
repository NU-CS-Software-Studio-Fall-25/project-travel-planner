Geocoder.configure(
  # Geocoding options
  timeout: 5,
  lookup: :google,
  api_key: (ENV['GOOGLE_MAPS_API_KEY'] || Rails.application.credentials.dig(:google, :maps_api_key)),
  units: :km,
  use_https: true
)
