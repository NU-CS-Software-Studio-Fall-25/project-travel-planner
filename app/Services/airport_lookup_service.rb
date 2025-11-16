# app/Services/airport_lookup_service.rb

class AirportLookupService
  # Major airport mappings for common cities/countries
  AIRPORT_MAPPINGS = {
    # United States - Major Cities
    "New York" => ["JFK", "EWR", "LGA"],
    "Los Angeles" => ["LAX"],
    "Chicago" => ["ORD", "MDW"],
    "San Francisco" => ["SFO"],
    "Boston" => ["BOS"],
    "Washington" => ["IAD", "DCA"],
    "Seattle" => ["SEA"],
    "Miami" => ["MIA"],
    "Fort Lauderdale" => ["FLL"],
    "Las Vegas" => ["LAS"],
    "Phoenix" => ["PHX"],
    "Houston" => ["IAH", "HOU"],
    "Dallas" => ["DFW", "DAL"],
    "Atlanta" => ["ATL"],
    "Denver" => ["DEN"],
    "Orlando" => ["MCO"],
    "Philadelphia" => ["PHL"],
    "San Diego" => ["SAN"],
    "Austin" => ["AUS"],
    "Portland" => ["PDX"],
    "Minneapolis" => ["MSP"],
    "Tampa" => ["TPA"],
    "Fort Myers" => ["RSW"],
    "Destin" => ["VPS"],
    "Myrtle Beach" => ["MYR"],
    "Charleston" => ["CHS"],
    "Savannah" => ["SAV"],
    "Key West" => ["EYW"],
    "Naples" => ["APF"],
    "Honolulu" => ["HNL"],
    
    # Canada
    "Toronto" => ["YYZ"],
    "Vancouver" => ["YVR"],
    "Montreal" => ["YUL"],
    "Calgary" => ["YYC"],
    
    # Europe
    "London" => ["LHR", "LGW", "STN"],
    "Paris" => ["CDG", "ORY"],
    "Rome" => ["FCO"],
    "Madrid" => ["MAD"],
    "Barcelona" => ["BCN"],
    "Amsterdam" => ["AMS"],
    "Berlin" => ["BER"],
    "Munich" => ["MUC"],
    "Vienna" => ["VIE"],
    "Zurich" => ["ZRH"],
    "Athens" => ["ATH"],
    "Dublin" => ["DUB"],
    "Brussels" => ["BRU"],
    "Copenhagen" => ["CPH"],
    "Stockholm" => ["ARN"],
    "Oslo" => ["OSL"],
    "Helsinki" => ["HEL"],
    "Prague" => ["PRG"],
    "Budapest" => ["BUD"],
    "Warsaw" => ["WAW"],
    "Lisbon" => ["LIS"],
    "Milan" => ["MXP", "LIN"],
    "Venice" => ["VCE"],
    "Florence" => ["FLR"],
    "Istanbul" => ["IST"],
    
    # Asia
    "Tokyo" => ["NRT", "HND"],
    "Singapore" => ["SIN"],
    "Hong Kong" => ["HKG"],
    "Bangkok" => ["BKK"],
    "Seoul" => ["ICN"],
    "Beijing" => ["PEK"],
    "Shanghai" => ["PVG"],
    "Dubai" => ["DXB"],
    "Mumbai" => ["BOM"],
    "Delhi" => ["DEL"],
    "Kuala Lumpur" => ["KUL"],
    "Manila" => ["MNL"],
    "Jakarta" => ["CGK"],
    "Taipei" => ["TPE"],
    
    # Australia & New Zealand
    "Sydney" => ["SYD"],
    "Melbourne" => ["MEL"],
    "Brisbane" => ["BNE"],
    "Auckland" => ["AKL"],
    
    # South America
    "Buenos Aires" => ["EZE"],
    "São Paulo" => ["GRU"],
    "Rio de Janeiro" => ["GIG"],
    "Lima" => ["LIM"],
    "Santiago" => ["SCL"],
    "Bogotá" => ["BOG"],
    
    # Africa
    "Cairo" => ["CAI"],
    "Johannesburg" => ["JNB"],
    "Cape Town" => ["CPT"],
    "Nairobi" => ["NBO"],
    
    # Mexico & Central America
    "Mexico City" => ["MEX"],
    "Cancún" => ["CUN"],
    "Guadalajara" => ["GDL"],
    "San José" => ["SJO"],
    "Panama City" => ["PTY"]
  }.freeze

  # Country to major airport mappings (fallback)
  COUNTRY_AIRPORTS = {
    "United States" => ["JFK", "LAX", "ORD"],
    "Canada" => ["YYZ", "YVR"],
    "United Kingdom" => ["LHR"],
    "France" => ["CDG"],
    "Germany" => ["FRA"],
    "Italy" => ["FCO"],
    "Spain" => ["MAD"],
    "Japan" => ["NRT"],
    "Australia" => ["SYD"],
    "China" => ["PEK"]
  }.freeze

  def initialize
    # Could be extended to use an external API for more comprehensive lookups
  end

  # Find airports for a location string (city, state, country format)
  def find_airports(location_string)
    return [] if location_string.blank?

    Rails.logger.info "Looking up airports for: #{location_string}"

    # Parse the location string
    parts = location_string.split(',').map(&:strip)
    
    # Try to match city name first
    city = parts.first
    country = parts.last if parts.length >= 2
    
    # Look for exact city match
    airports = find_by_city(city)
    
    # If no match and we have a country, try country-level lookup
    if airports.empty? && country.present?
      airports = find_by_country(country)
    end
    
    # If still no match, try fuzzy matching on city
    if airports.empty?
      airports = fuzzy_find_city(city)
    end
    
    Rails.logger.info "Found airports: #{airports.inspect}"
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

  def find_by_city(city)
    return [] if city.blank?
    
    # Direct match
    match = AIRPORT_MAPPINGS.find { |key, _| key.downcase == city.downcase }
    return match[1] if match
    
    # Partial match (e.g., "San Francisco, CA" matches "San Francisco")
    match = AIRPORT_MAPPINGS.find { |key, _| city.downcase.include?(key.downcase) || key.downcase.include?(city.downcase) }
    match ? match[1] : []
  end

  def find_by_country(country)
    return [] if country.blank?
    
    # Normalize country names
    normalized_country = normalize_country_name(country)
    # Don't return country-level fallback if we're looking for a specific city
    # This causes issues where "Destin" returns JFK, LAX, ORD instead of nothing
    []
  end

  def fuzzy_find_city(city)
    return [] if city.blank?
    
    # Try to find cities that contain the search term or vice versa
    match = AIRPORT_MAPPINGS.find do |key, _|
      city.downcase.include?(key.downcase) || key.downcase.include?(city.downcase)
    end
    
    match ? match[1] : []
  end

  def normalize_country_name(country)
    mappings = {
      "USA" => "United States",
      "US" => "United States",
      "U.S." => "United States",
      "U.S.A." => "United States",
      "UK" => "United Kingdom",
      "U.K." => "United Kingdom",
      "England" => "United Kingdom",
      "Scotland" => "United Kingdom",
      "Wales" => "United Kingdom"
    }
    
    mappings[country] || country
  end
end
