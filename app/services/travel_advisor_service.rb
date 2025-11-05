require 'httparty'

class TravelAdvisorService
  include HTTParty

  def initialize(key: ENV['RAPIDAPI_KEY'] || (ENV['RAPIDAPI_KEY'] = ENV.dig('rapidapi','key')), host: ENV['RAPIDAPI_HOST'] || (ENV['RAPIDAPI_HOST'] = ENV.dig('rapidapi','host')))
    @key = key
    @host = host || 'travel-advisor.p.rapidapi.com'
    @headers = {
      'X-RapidAPI-Key' => @key,
      'X-RapidAPI-Host' => @host,
      'Accept' => 'application/json'
    }
  end

  # Fetch attractions/places near given coordinates using Travel Advisor endpoints via RapidAPI
  def places_near(lat:, lng:, radius_m: 2000, limit: 8)
    return [] if lat.blank? || lng.blank? || @key.blank?

    cache_key = "ta:places:near:#{lat}:#{lng}:#{radius_m}:#{limit}"
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      # RapidAPI Travel-Advisor endpoints can vary; use list-by-latlng as a common endpoint
      query = { latitude: lat, longitude: lng, limit: limit }
      url = "https://#{@host}/attractions/list-by-lat-lng"
      resp = HTTParty.get(url, headers: @headers, query: query)

      if resp.success?
        parse_places(resp.parsed_response)
      else
        Rails.logger.warn "TravelAdvisor API error: #{resp.code} #{resp.body}" if defined?(Rails.logger)
        []
      end
    end
  rescue => e
    Rails.logger.error "TravelAdvisorService error: #{e.class} #{e.message}" if defined?(Rails.logger)
    []
  end

  private

  def parse_places(json)
    # parse a couple of common keys; actual structure depends on provider
    items = json['data'] || json['results'] || json['data'] || []
    items = items.first(50) if items.is_a?(Array)

    Array(items).map do |item|
      {
        id: item['location_id'] || item['id'] || item['place_id'],
        name: item['name'] || item['title'],
        rating: item['rating'] || item['score'],
        address: item['address'] || item['vicinity'],
        photo: item.dig('photo','images','small','url') || item.dig('photo','images','thumbnail','url') || item['thumbnail'],
        url: item['web_url'] || item['url'] || item['link'],
        distance_km: item['distance'] || item['distance_km']
      }
    end
  end
end
