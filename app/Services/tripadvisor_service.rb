# app/Services/tripadvisor_service.rb

require "net/http"
require "json"

class TripadvisorService
  BASE_URL = "https://api.content.tripadvisor.com/api/v1"

  def initialize
    @api_key = ENV["TRIPADVISOR_API_KEY"]
  end

  # Search for a location and get photos
  # destination_city should be like "Burlington, Vermont" or "Paris, France"
  def get_location_photos(destination_city, destination_country, limit = 7)
    Rails.logger.info "="*80
    Rails.logger.info "TripAdvisor API Request Started"
    Rails.logger.info "Destination City: '#{destination_city}'"
    Rails.logger.info "Destination Country: '#{destination_country}'"
    Rails.logger.info "Limit: #{limit}"
    Rails.logger.info "API Key present: #{@api_key.present?}"
    Rails.logger.info "="*80

    return default_error_response unless @api_key.present?

    begin
      # Strategy 1: Try to get photos from the main city location
      location_id = search_location(destination_city, destination_country)

      return default_error_response unless location_id

      location_details = get_location_details(location_id)
      return default_error_response unless location_details

      photos = get_photos(location_id, limit)

      # Strategy 2: If we got very few photos, search for popular attractions in the city
      if photos.length < limit
        Rails.logger.info "Only got #{photos.length} photos from city. Searching for attractions to reach #{limit} photos..."
        attraction_photos = search_attraction_photos(destination_city, destination_country, limit - photos.length)
        photos += attraction_photos
      end

      # Combine the information
      {
        success: true,
        location_id: location_id,
        location_name: location_details["name"],
        description: location_details["description"],
        web_url: location_details["web_url"],
        photos: photos.uniq { |p| p[:url] } # Remove duplicates by URL
      }
    rescue => e
      Rails.logger.error "TripAdvisor API Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      default_error_response
    end
  end

  private

  # Search for attractions in the city and get their photos
  def search_attraction_photos(destination_city, destination_country, needed_count)
    # Try different search queries to find actual attractions
    search_queries = [
      "things to do in #{destination_city}",
      "#{destination_city} attractions",
      "#{destination_city} beach",
      "#{destination_city} downtown",
      "#{destination_city} landmarks",
      "parks in #{destination_city}"
    ]

    all_photos = []
    seen_location_ids = Set.new

    search_queries.each do |search_query|
      break if all_photos.length >= needed_count

      uri = URI("#{BASE_URL}/location/search")
      params = {
        key: @api_key,
        searchQuery: search_query,
        language: "en"
      }
      uri.query = URI.encode_www_form(params)

      Rails.logger.info "Searching attractions: #{search_query}"

      response = make_request(uri)
      next unless response

      data = JSON.parse(response.body)

      # Get photos from different locations (excluding hotels/restaurants and previously seen)
      if data["data"]&.any?
        locations = data["data"].select do |loc|
          location_id = loc["location_id"]
          name = loc["name"].to_s.downcase

          # Skip if we've already processed this location
          next false if seen_location_ids.include?(location_id)

          # Skip hotels, restaurants, and the city itself
          !name.include?("hotel") &&
          !name.include?("restaurant") &&
          !name.include?("hostel") &&
          !name.match?(/\b(#{destination_city.split(',').first})\b/i) # Skip if it's just the city name
        end.take(5) # Increased from 3 to 5

        Rails.logger.info "Found #{locations.length} unique locations for photos"

        locations.each do |location|
          location_id = location["location_id"]
          seen_location_ids.add(location_id)

          Rails.logger.info "Fetching photos from: #{location['name']} (ID: #{location_id})"

          # Get 3 photos from each location (increased from 2)
          photos = get_photos(location_id, 3)
          all_photos += photos

          break if all_photos.length >= needed_count
        end
      end
    end

    Rails.logger.info "Collected #{all_photos.length} photos from attractions (needed #{needed_count})"
    all_photos.take(needed_count)
  rescue => e
    Rails.logger.error "Error searching attractions: #{e.message}"
    []
  end

  def search_location(destination_city, destination_country)
    # Construct search query
    search_query = "#{destination_city}, #{destination_country}"

    Rails.logger.info "---"
    Rails.logger.info "Searching TripAdvisor for location..."
    Rails.logger.info "Search Query: '#{search_query}'"

    uri = URI("#{BASE_URL}/location/search")
    params = {
      key: @api_key,
      searchQuery: search_query,
      language: "en"
    }
    uri.query = URI.encode_www_form(params)

    Rails.logger.info "Full Search URL: #{uri}"
    Rails.logger.info "Encoded Query Parameter: '#{URI.encode_www_form_component(search_query)}'"

    response = make_request(uri)
    return nil unless response

    data = JSON.parse(response.body)

    # Get the first location from search results that is NOT a tour/activity
    # Filter out tours, activities, and services - we only want actual places
    if data["data"]&.any?
      # Filter results to find actual destinations (not tours/activities)
      actual_locations = data["data"].reject do |loc|
        name = loc["name"].to_s.downcase
        # Skip if it's clearly a tour, activity, transfer, or service
        name.include?("tour") ||
        name.include?("transfer") ||
        name.include?("activity") ||
        name.include?("shuttle") ||
        name.include?("service") ||
        name.include?("trip") ||
        name.include?("from ") ||  # "Tour from Calgary"
        name.include?(" to ")      # "Transfer to Airport"
      end

      Rails.logger.info "Filtered out #{data['data'].length - actual_locations.length} tours/activities"
      Rails.logger.info "Found #{actual_locations.length} actual locations"

      if actual_locations.any?
        location_id = actual_locations.first["location_id"]
        Rails.logger.info "Selected location ID: #{location_id} (#{actual_locations.first['name']})"
        return location_id
      else
        # If all results were tours, just use the first one anyway
        location_id = data["data"].first["location_id"]
        Rails.logger.warn "All results were tours/activities, using first: #{location_id}"
        return location_id
      end
    end

    Rails.logger.warn "No location found for: #{search_query}"
    nil
  rescue => e
    Rails.logger.error "Error searching location: #{e.message}"
    nil
  end

  def get_location_details(location_id)
    uri = URI("#{BASE_URL}/location/#{location_id}/details")
    params = {
      key: @api_key,
      language: "en",
      currency: "USD"
    }
    uri.query = URI.encode_www_form(params)

    Rails.logger.info "TripAdvisor Details URL: #{uri}"

    response = make_request(uri)
    return nil unless response

    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Error getting location details: #{e.message}"
    nil
  end

  def get_photos(location_id, limit = 5)
    # Request MANY more photos than needed so we can filter out ads and still have enough
    # TripAdvisor allows up to 100 photos per request
    request_limit = [ limit * 10, 50 ].min # Request 10x more, max 50 to ensure we get enough after filtering

    uri = URI("#{BASE_URL}/location/#{location_id}/photos")
    params = {
      key: @api_key,
      language: "en",
      limit: request_limit
    }
    uri.query = URI.encode_www_form(params)

    Rails.logger.info "TripAdvisor Photos URL: #{uri}"

    response = make_request(uri)
    return [] unless response

    data = JSON.parse(response.body)

    # Extract and filter photo information
    all_photos = []
    if data["data"]&.any?
      data["data"].each do |photo|
        caption = photo["caption"].to_s.strip

        # SKIP PHOTOS THAT LOOK LIKE ADS:
        # 1. Long captions (>100 chars) are usually promotional text
        next if caption.length > 100

        # 2. Captions with promotional keywords
        promotional_keywords = [
          "offer", "service", "airport", "transportation", "contact",
          "book", "reservation", "available", "call", "email",
          "website", "visit us", "special", "discount", "deal", "entertainment"
        ]
        next if promotional_keywords.any? { |keyword| caption.downcase.include?(keyword) }

        # 3. Captions with phone numbers, emails, or URLs
        next if caption.match?(/\d{3}[-.\s]?\d{3}[-.\s]?\d{4}/) # Phone numbers
        next if caption.match?(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/) # Emails
        next if caption.match?(/https?:\/\/|www\./) # URLs

        # Get the best quality image URL
        image_url = photo.dig("images", "large", "url") ||
                   photo.dig("images", "medium", "url") ||
                   photo.dig("images", "small", "url")

        next unless image_url

        # Calculate quality score for sorting
        quality_score = 0
        quality_score += 100 if photo["is_blessed"] # TripAdvisor's quality flag
        quality_score += 50 if caption.blank? || caption.length < 50 # Short/no caption = likely user photo
        quality_score += 25 if photo.dig("images", "large", "url").present? # Has large image
        quality_score -= 30 if caption.length > 50 # Penalize longer captions

        all_photos << {
          id: photo["id"],
          caption: caption.presence || "Photo of the location",
          url: image_url,
          width: photo.dig("images", "large", "width") || photo.dig("images", "medium", "width"),
          height: photo.dig("images", "large", "height") || photo.dig("images", "medium", "height"),
          is_blessed: photo["is_blessed"] || false,
          quality_score: quality_score
        }
      end
    end

    # Sort by quality score (blessed and short/no captions first) and take the limit
    sorted_photos = all_photos.sort_by { |p| -p[:quality_score] }.take(limit)

    # Remove quality_score from output (it was just for sorting)
    sorted_photos.each { |p| p.delete(:quality_score) }

    Rails.logger.info "Filtered to #{sorted_photos.length} quality photos from #{data['data']&.length || 0} total (filtered out ads)"

    sorted_photos
  rescue => e
    Rails.logger.error "Error getting photos: #{e.message}"
    []
  end

  def make_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"

    # Use domain restriction for production (Heroku), IP restriction for development
    if Rails.env.production?
      # For Heroku: Use domain-based restriction
      # The Referer must match your domain restriction exactly
      request["Referer"] = "https://travel-planner-cs397-9396d2cb2102.herokuapp.com"
      Rails.logger.info "Using domain restriction with Referer: #{request['Referer']}"
    else
      # For local development: Use IP-based restriction (no Referer needed)
      Rails.logger.info "Using IP restriction for local development"
    end

    Rails.logger.info "Making request to: #{uri}"

    response = http.request(request)

    Rails.logger.info "Response code: #{response.code}"
    Rails.logger.info "Response body preview: #{response.body[0..200]}" # First 200 chars

    if response.code.to_i == 200
      response
    else
      Rails.logger.error "TripAdvisor API returned status #{response.code}: #{response.body}"
      nil
    end
  end

  def default_error_response
    {
      success: false,
      location_id: nil,
      location_name: nil,
      description: nil,
      web_url: nil,
      photos: []
    }
  end
end
