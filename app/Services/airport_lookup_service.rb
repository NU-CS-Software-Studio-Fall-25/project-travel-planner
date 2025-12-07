# app/Services/airport_lookup_service.rb

class AirportLookupService
  # Cache for parsed airport data
  @@airports_data = nil
  @@airports_by_city = nil
  @@airports_by_country = nil

  # Dataset file path
  AIRPORTS_DATA_FILE = Rails.root.join("app", "assets", "dataset", "airports.dat")

  def initialize
    load_airports_data unless @@airports_data
  end

  # Find airports for a location string (city, state, country format)
  def find_airports(location_string)
    return [] if location_string.blank?

    Rails.logger.info "Looking up airports for: #{location_string}"

    # Parse the location string
    parts = location_string.split(",").map(&:strip)

    # Try to match city name first
    city = parts.first
    country = parts.last if parts.length >= 2

    # Look for exact city match (with country filter if provided)
    airports = find_by_city_and_country(city, country)

    # If still no match, try fuzzy matching on city (with country filter)
    if airports.empty?
      airports = fuzzy_find_city(city, country)
    end

    # If still no match and we have a country, get major airports for that country
    if airports.empty? && country.present?
      airports = get_major_airports_for_country(country)
    end

    # Prioritize international airports
    airports = prioritize_international_airports(airports)

    Rails.logger.info "Found airports (prioritized): #{airports.inspect}"
    airports
  end

  # Find nearest major airport code (returns first/primary airport)
  def find_nearest_airport(location_string)
    airports = find_airports(location_string)
    airport = airports.first || "JFK" # Default fallback to JFK
    Rails.logger.info "Primary airport for #{location_string}: #{airport}"
    airport
  end

  private

  # Load and parse the airports dataset
  def load_airports_data
    return if @@airports_data # Already loaded

    Rails.logger.info "Loading airports data from #{AIRPORTS_DATA_FILE}"

    @@airports_data = []
    @@airports_by_city = Hash.new { |h, k| h[k] = [] }
    @@airports_by_country = Hash.new { |h, k| h[k] = [] }

    begin
      File.foreach(AIRPORTS_DATA_FILE, encoding: "UTF-8") do |line|
        # Parse CSV line: ID, Name, City, Country, IATA, ICAO, ...
        parts = line.strip.split(",")
        next if parts.length < 6

        # Remove quotes from fields
        airport_name = parts[1]&.gsub(/^"|"$/, "")
        city = parts[2]&.gsub(/^"|"$/, "")
        country = parts[3]&.gsub(/^"|"$/, "")
        iata_code = parts[4]&.gsub(/^"|"$/, "")

        # Skip if no IATA code (not a commercial airport) or is '\N' (null)
        next if iata_code.nil? || iata_code.empty? || iata_code == '\N' || iata_code.length != 3

        airport_data = {
          name: airport_name,
          city: city,
          country: country,
          iata: iata_code
        }

        @@airports_data << airport_data

        # Index by city (normalized)
        normalized_city = normalize_string(city)
        @@airports_by_city[normalized_city] << iata_code

        # Also index by the base city name (e.g., "Queenstown" from "Queenstown International")
        # This helps match cities when the dataset includes airport qualifiers
        base_city = city.gsub(/\s+(International|Airport|Airfield|Municipal|Regional|County).*$/i, "").strip
        if base_city != city
          normalized_base = normalize_string(base_city)
          @@airports_by_city[normalized_base] << iata_code unless normalized_base == normalized_city
        end

        # Index by country (normalized)
        normalized_country = normalize_country_name(country)
        @@airports_by_country[normalized_country] << iata_code
      end

      Rails.logger.info "Loaded #{@@airports_data.length} airports"
      Rails.logger.info "Indexed #{@@airports_by_city.keys.length} cities"
      Rails.logger.info "Indexed #{@@airports_by_country.keys.length} countries"
    rescue => e
      Rails.logger.error "Error loading airports data: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Initialize with empty data to prevent repeated errors
      @@airports_data = []
      @@airports_by_city = {}
      @@airports_by_country = {}
    end
  end

  def find_by_city_and_country(city, country = nil)
    return [] if city.blank?

    normalized_city = normalize_string(city)
    normalized_country = country.present? ? normalize_country_name(country) : nil

    # Exact match first
    airports = @@airports_by_city[normalized_city]

    # If we have airports and a country filter, filter by country
    if airports.present? && normalized_country.present?
      # Filter airports to only those in the specified country
      filtered = filter_airports_by_country(airports, normalized_country)
      return filtered if filtered.present?
    end

    return airports if airports.present?
    []
  end

  def filter_airports_by_country(airport_codes, country)
    return airport_codes if country.blank?

    # Find airports that match the country
    airport_codes.select do |code|
      airport = @@airports_data.find { |a| a[:iata] == code }
      airport && normalize_country_name(airport[:country]) == country
    end
  end

  def fuzzy_find_city(city, country = nil)
    return [] if city.blank?

    normalized_city = normalize_string(city)
    normalized_country = country.present? ? normalize_country_name(country) : nil

    # Special cases: Search for airports in the same region
    # For example, Kyoto -> Osaka (nearby major city)
    region_mappings = {
      "kyoto" => "osaka",
      "nara" => "osaka",
      "kobe" => "osaka",
      "yokohama" => "tokyo",
      "cambridge" => "boston",
      "somerville" => "boston"
    }

    if region_mappings[normalized_city]
      nearby_city = region_mappings[normalized_city]
      airports = @@airports_by_city[nearby_city]

      # Filter by country if provided
      if airports.present? && normalized_country.present?
        filtered = filter_airports_by_country(airports, normalized_country)
        return filtered if filtered.present?
      end

      return airports if airports.present?
    end

    # Try fuzzy matching - look for cities that start with the search term
    # This is more restrictive to avoid false matches
    @@airports_by_city.each do |indexed_city, codes|
      # Only match if the indexed city starts with the search term or vice versa
      # This prevents "London, Canada" from matching "London, UK"
      if indexed_city.start_with?(normalized_city) || normalized_city.start_with?(indexed_city)
        # Filter by country if provided
        if normalized_country.present?
          filtered = filter_airports_by_country(codes, normalized_country)
          return filtered if filtered.present?
        else
          return codes if codes.present?
        end
      end
    end

    []
  end

  def get_major_airports_for_country(country)
    return [] if country.blank?

    normalized_country = normalize_country_name(country)
    all_airports = @@airports_by_country[normalized_country] || []

    # Return up to 3 major airports for the country
    # Prioritize airports from capital or major cities
    major_cities = {
      "united states" => [ "New York", "Los Angeles", "Chicago" ],
      "japan" => [ "Tokyo", "Osaka", "Nagoya" ],
      "new zealand" => [ "Auckland", "Christchurch", "Wellington", "Queenstown" ],
      "iceland" => [ "Reykjavik", "Keflavik" ],
      "australia" => [ "Sydney", "Melbourne", "Brisbane" ]
    }

    cities = major_cities[normalized_country]
    if cities.present?
      major_airports = []
      cities.each do |city|
        normalized = normalize_string(city)
        city_airports = @@airports_by_city[normalized]
        major_airports.concat(city_airports) if city_airports.present?
      end
      return major_airports.take(3) if major_airports.any?
    end

    # Fallback: return first 3 airports for the country
    all_airports.take(3)
  end

  def prioritize_international_airports(airport_codes)
    return airport_codes if airport_codes.length <= 1

    # Sort airports by priority (international/major airports first)
    sorted = airport_codes.sort_by do |code|
      airport = @@airports_data.find { |a| a[:iata] == code }
      next 999 unless airport # Unknown airports last

      name = airport[:name].to_s.downcase

      # Priority scoring (lower is better)
      score = 0

      # Highest priority: International airports
      score -= 100 if name.include?("international")

      # High priority: Well-known major airports
      major_codes = %w[JFK LHR CDG NRT HND LAX ORD SFO LGA SYD MEL ICN DXB SIN HKG]
      score -= 50 if major_codes.include?(code)

      # Medium priority: Named after cities or regions (not generic names)
      score -= 20 if name.match?(/airport|aerodrome|field|base/) && !name.match?(/municipal|regional|county|airfield/)

      # Lower priority: Municipal, regional, or small airports
      score += 30 if name.match?(/municipal|regional|county|airfield/)

      # Lower priority: Military or special use
      score += 40 if name.match?(/air force|afb|base|naval|military/)

      score
    end

    sorted
  end

  def normalize_string(str)
    return "" if str.blank?

    # Remove accents, convert to lowercase, remove extra spaces
    str.to_s
       .unicode_normalize(:nfkd)
       .encode("ASCII", replace: "")
       .downcase
       .strip
       .gsub(/\s+/, " ")
  end

  def normalize_country_name(country)
    return "" if country.blank?

    # Normalize the country string first
    normalized = normalize_string(country)

    # Country name mappings
    mappings = {
      "usa" => "united states",
      "us" => "united states",
      "u.s." => "united states",
      "u.s.a." => "united states",
      "america" => "united states",
      "uk" => "united kingdom",
      "u.k." => "united kingdom",
      "england" => "united kingdom",
      "scotland" => "united kingdom",
      "wales" => "united kingdom",
      "great britain" => "united kingdom"
    }

    mappings[normalized] || normalized
  end
end
