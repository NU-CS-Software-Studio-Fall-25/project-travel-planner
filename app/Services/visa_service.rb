# app/Services/visa_service.rb
# Service to interact with Travel Buddy Visa Requirements API via RapidAPI

require 'net/http'
require 'json'

class VisaService
  API_HOST = 'visa-requirement.p.rapidapi.com'
  API_BASE_URL = "https://#{API_HOST}"
  CACHE_EXPIRY = 30.days

  def initialize(passport_country, destination_country)
    @passport_country = passport_country
    @destination_country = destination_country
    @api_key = ENV.fetch('RAPIDAPI_KEY')
  end

  # Main method to get visa requirements
  # Returns structured visa information
  def get_visa_requirements
    # Convert country names to ISO codes
    passport_code = CountryCodeMapper.to_iso_code(@passport_country)
    destination_code = CountryCodeMapper.to_iso_code(@destination_country)

    if passport_code.nil?
      Rails.logger.error "❌ Invalid passport country: #{@passport_country}"
      return fallback_response("Invalid passport country: #{@passport_country}")
    end

    if destination_code.nil?
      Rails.logger.error "❌ Invalid destination country: #{@destination_country}"
      return fallback_response("Invalid destination country: #{@destination_country}")
    end

    # Check if passport and destination are the same
    if passport_code == destination_code
      Rails.logger.info "ℹ️  Same country travel: #{@passport_country}"
      return domestic_travel_response
    end

    # Check cache first
    cached_data = check_cache(passport_code, destination_code)
    return cached_data if cached_data

    # Call API
    api_response = call_visa_api(passport_code, destination_code)
    
    if api_response[:success]
      # Parse and structure the response
      structured_data = parse_api_response(api_response[:data])
      
      # Cache the result
      cache_visa_data(passport_code, destination_code, structured_data)
      
      structured_data
    else
      fallback_response(api_response[:error])
    end
  rescue => e
    Rails.logger.error "❌ Visa API Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    fallback_response("API error: #{e.message}")
  end

  private

  # Call the Visa Requirements API
  def call_visa_api(passport_code, destination_code)
    uri = URI("#{API_BASE_URL}/v2/visa/check")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    http.open_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['X-RapidAPI-Key'] = @api_key
    request['X-RapidAPI-Proxy-Secret'] = @api_key  # Some APIs use this instead
    request['X-RapidAPI-Host'] = API_HOST
    request.body = {
      passport: passport_code,
      destination: destination_code
    }.to_json

    Rails.logger.info "🔍 Calling Visa API: #{passport_code} → #{destination_code}"

    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body, symbolize_names: true)
      Rails.logger.info "✅ Visa API Success: #{passport_code} → #{destination_code}"
      { success: true, data: data }
    else
      error_msg = "API returned #{response.code}: #{response.body}"
      Rails.logger.error "❌ Visa API Error: #{error_msg}"
      { success: false, error: error_msg }
    end
  rescue => e
    Rails.logger.error "❌ Visa API Request Failed: #{e.message}"
    { success: false, error: e.message }
  end

  # Parse API response into structured format
  def parse_api_response(data)
    visa_data = data[:data] || {}
    visa_rules = visa_data[:visa_rules] || {}
    primary_rule = visa_rules[:primary_rule] || {}
    secondary_rule = visa_rules[:secondary_rule] || {}
    mandatory_reg = visa_data[:mandatory_registration] || {}
    destination_info = visa_data[:destination] || {}
    exception_rule = visa_rules[:exception_rule] || {}

    {
      success: true,
      
      # Primary visa information
      visa_status: primary_rule[:name] || "Unknown",
      visa_duration: primary_rule[:duration],
      visa_color: primary_rule[:color] || "yellow",
      visa_link: primary_rule[:link],
      
      # Secondary visa option (alternative)
      alternative_visa: secondary_rule[:name],
      alternative_duration: secondary_rule[:duration],
      alternative_link: secondary_rule[:link],
      
      # Mandatory registration (e.g., e-Arrival)
      mandatory_registration: mandatory_reg[:name],
      registration_link: mandatory_reg[:link],
      registration_color: mandatory_reg[:color],
      
      # Passport requirements
      passport_validity: destination_info[:passport_validity],
      
      # Exception rules (e.g., visa waiver for US visa holders)
      exception_available: exception_rule.present?,
      exception_text: exception_rule[:full_text],
      exception_countries: exception_rule[:country_codes],
      
      # Destination info (optional)
      destination_capital: destination_info[:capital],
      destination_currency: destination_info[:currency],
      embassy_url: destination_info[:embassy_url],
      
      # Metadata
      passport_code: visa_data[:passport][:code],
      destination_code: visa_data[:destination][:code],
      api_version: data[:meta][:version],
      generated_at: data[:meta][:generated_at]
    }
  end

  # Check if data is cached
  def check_cache(passport_code, destination_code)
    # TODO: Implement database caching in Phase 2
    # For now, return nil (no cache)
    nil
  end

  # Cache visa data
  def cache_visa_data(passport_code, destination_code, data)
    # TODO: Implement database caching in Phase 2
    # For now, just log
    Rails.logger.info "💾 Would cache: #{passport_code} → #{destination_code}"
  end

  # Fallback response when API fails
  def fallback_response(error_message)
    {
      success: false,
      error: error_message,
      visa_status: "Check visa requirements",
      visa_color: "yellow",
      visa_duration: nil,
      fallback: true
    }
  end

  # Response for domestic travel (same country)
  def domestic_travel_response
    {
      success: true,
      visa_status: "No visa required (domestic travel)",
      visa_color: "green",
      visa_duration: "Unlimited",
      domestic: true,
      passport_validity: "Valid ID required"
    }
  end
end
