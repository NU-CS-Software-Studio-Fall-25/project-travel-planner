# app/Services/serpapi_flight_service.rb

require 'net/http'
require 'uri'
require 'json'

class SerpapiFlightService
  API_KEY = '96e7a7f8814b6000ef60d17202cedca1b66d061c4024101b2dcb3152ffa33ff4'
  BASE_URL = 'https://serpapi.com/search'

  def initialize(preferences)
    @preferences = preferences
    @airport_lookup = AirportLookupService.new
  end

  # Get flight price for a given destination
  # Returns hash with: { success: true/false, price: amount, details: {...}, error: message }
  def get_flight_price(destination_city, destination_country)
    begin
      # Find airports
      departure_airport = @airport_lookup.find_nearest_airport(@preferences[:current_location])
      arrival_airports = @airport_lookup.find_airports("#{destination_city}, #{destination_country}")
      
      if arrival_airports.empty?
        Rails.logger.warn "No airports found for #{destination_city}, #{destination_country}"
        return {
          success: false,
          error: "Could not find airport for #{destination_city}"
        }
      end
      
      Rails.logger.info "=== SerpAPI Flight Search ==="
      Rails.logger.info "From: #{departure_airport} (#{@preferences[:current_location]})"
      Rails.logger.info "To: #{destination_city}, #{destination_country}"
      Rails.logger.info "Available arrival airports: #{arrival_airports.join(', ')}"
      Rails.logger.info "Dates: #{@preferences[:start_date]} to #{@preferences[:end_date]}"
      
      # Check all available airports to find the cheapest flight
      best_result = find_cheapest_flight_across_airports(
        departure_airport: departure_airport,
        arrival_airports: arrival_airports,
        destination_city: destination_city
      )
      
      best_result
      
    rescue => e
      Rails.logger.error "=== SerpAPI Flight Error ==="
      Rails.logger.error "Error: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
      
      {
        success: false,
        error: "Flight search failed: #{e.message}"
      }
    end
  end

  private

  # Check all available airports and return the cheapest flight option
  def find_cheapest_flight_across_airports(departure_airport:, arrival_airports:, destination_city:)
    valid_results = []
    errors = []
    
    # Limit to first 3 airports to avoid excessive API calls
    airports_to_check = arrival_airports.take(3)
    
    Rails.logger.info "Checking #{airports_to_check.length} airports for best price..."
    
    airports_to_check.each do |arrival_airport|
      Rails.logger.info "  → Checking #{arrival_airport}..."
      
      # Make flight request for this airport
      response = make_flight_request(
        departure_airport: departure_airport,
        arrival_airport: arrival_airport,
        outbound_date: @preferences[:start_date],
        return_date: @preferences[:end_date],
        adults: @preferences[:number_of_travelers] || 1
      )
      
      if response[:success]
        result = parse_flight_response(response[:data], departure_airport, arrival_airport, destination_city)
        
        if result[:success]
          valid_results << result
          Rails.logger.info "    ✓ Found flight via #{arrival_airport}: $#{result[:price]}"
        else
          errors << { airport: arrival_airport, error: result[:error] }
          Rails.logger.warn "    ✗ #{arrival_airport}: #{result[:error]}"
        end
      else
        errors << { airport: arrival_airport, error: response[:error] }
        Rails.logger.warn "    ✗ #{arrival_airport}: #{response[:error]}"
      end
      
      # Small delay to avoid rate limiting (optional)
      sleep(0.5) if airports_to_check.length > 1
    end
    
    # Return the cheapest valid result
    if valid_results.any?
      cheapest = valid_results.min_by { |r| r[:price] }
      Rails.logger.info "=== Best Option Found ==="
      Rails.logger.info "Airport: #{cheapest[:details][:arrival_airport]}"
      Rails.logger.info "Price: $#{cheapest[:price]}"
      return cheapest
    end
    
    # If no valid results, return error with details
    Rails.logger.error "No valid flights found for any airport"
    {
      success: false,
      error: "No flights available for #{destination_city}",
      details: {
        airports_checked: airports_to_check,
        errors: errors
      }
    }
  end

  def make_flight_request(departure_airport:, arrival_airport:, outbound_date:, return_date:, adults: 1)
    # Build query parameters
    params = {
      engine: 'google_flights',
      api_key: API_KEY,
      departure_id: departure_airport,
      arrival_id: arrival_airport,
      outbound_date: outbound_date,
      return_date: return_date,
      type: '1', # Round trip
      travel_class: '1', # Economy
      adults: adults.to_s,
      currency: 'USD',
      hl: 'en',
      gl: 'us'
    }
    
    # Build URL
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(params)
    
    Rails.logger.info "SerpAPI Request URL: #{uri}"
    
    # Make HTTP request
    begin
      response = Net::HTTP.get_response(uri)
      
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body, symbolize_names: true)
        
        # Check for API errors
        if data[:error]
          Rails.logger.error "SerpAPI Error: #{data[:error]}"
          return {
            success: false,
            error: data[:error]
          }
        end
        
        {
          success: true,
          data: data
        }
      else
        Rails.logger.error "HTTP Error: #{response.code} - #{response.message}"
        {
          success: false,
          error: "HTTP #{response.code}: #{response.message}"
        }
      end
      
    rescue JSON::ParserError => e
      Rails.logger.error "JSON Parse Error: #{e.message}"
      {
        success: false,
        error: "Failed to parse API response"
      }
    rescue => e
      Rails.logger.error "Request Error: #{e.message}"
      {
        success: false,
        error: "Request failed: #{e.message}"
      }
    end
  end

  def parse_flight_response(data, departure_airport, arrival_airport, destination_city)
    # Get best flights from response
    best_flights = data[:best_flights] || []
    
    if best_flights.empty?
      Rails.logger.warn "No flights found in SerpAPI response"
      return {
        success: false,
        error: "No flights available for this route"
      }
    end
    
    # Get the cheapest flight
    cheapest_flight = best_flights.min_by { |f| f[:price] || Float::INFINITY }
    
    if cheapest_flight.nil? || cheapest_flight[:price].nil?
      Rails.logger.warn "No valid flight prices found"
      return {
        success: false,
        error: "No flight prices available"
      }
    end
    
    price = cheapest_flight[:price]
    
    Rails.logger.info "=== Flight Found ==="
    Rails.logger.info "Price: $#{price}"
    Rails.logger.info "Airline: #{cheapest_flight.dig(:flights, 0, :airline) || 'Unknown'}"
    
    # Extract flight details
    flights = cheapest_flight[:flights] || []
    outbound_flights = flights.select { |f| f[:departure_airport][:id] == departure_airport }
    return_flights = flights.select { |f| f[:arrival_airport][:id] == departure_airport }
    
    {
      success: true,
      price: price,
      details: {
        total_price: price,
        departure_airport: departure_airport,
        arrival_airport: arrival_airport,
        destination_city: destination_city,
        airline: cheapest_flight.dig(:flights, 0, :airline) || 'Various',
        duration: format_duration(outbound_flights.sum { |f| f[:duration] || 0 }),
        return_duration: format_duration(return_flights.sum { |f| f[:duration] || 0 }),
        stops: outbound_flights.length - 1,
        booking_token: cheapest_flight[:booking_token],
        flight_info: cheapest_flight
      }
    }
  end

  def format_duration(minutes)
    return "N/A" if minutes.nil? || minutes == 0
    
    hours = minutes / 60
    mins = minutes % 60
    
    if hours > 0 && mins > 0
      "#{hours}h #{mins}m"
    elsif hours > 0
      "#{hours}h"
    else
      "#{mins}m"
    end
  end
end
