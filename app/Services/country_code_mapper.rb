# app/Services/country_code_mapper.rb
# Converts country names to ISO Alpha-2 codes for Visa API

class CountryCodeMapper
  # Comprehensive mapping of country names to ISO Alpha-2 codes
  COUNTRY_CODES = {
    # Major countries
    "United States" => "US",
    "USA" => "US",
    "United Kingdom" => "GB",
    "UK" => "GB",
    "China" => "CN",
    "Japan" => "JP",
    "South Korea" => "KR",
    "Korea" => "KR",
    "Canada" => "CA",
    "Australia" => "AU",
    "France" => "FR",
    "Germany" => "DE",
    "Italy" => "IT",
    "Spain" => "ES",
    "Mexico" => "MX",
    "Brazil" => "BR",
    "India" => "IN",
    "Russia" => "RU",
    "Indonesia" => "ID",
    "Thailand" => "TH",
    "Singapore" => "SG",
    "Malaysia" => "MY",
    "Vietnam" => "VN",
    "Philippines" => "PH",
    "Netherlands" => "NL",
    "Belgium" => "BE",
    "Switzerland" => "CH",
    "Austria" => "AT",
    "Sweden" => "SE",
    "Norway" => "NO",
    "Denmark" => "DK",
    "Finland" => "FI",
    "Poland" => "PL",
    "Greece" => "GR",
    "Portugal" => "PT",
    "Ireland" => "IE",
    "New Zealand" => "NZ",
    "Argentina" => "AR",
    "Chile" => "CL",
    "Colombia" => "CO",
    "Peru" => "PE",
    "Egypt" => "EG",
    "South Africa" => "ZA",
    "Turkey" => "TR",
    "Türkiye" => "TR",
    "Israel" => "IL",
    "Saudi Arabia" => "SA",
    "UAE" => "AE",
    "United Arab Emirates" => "AE",
    "Qatar" => "QA",
    "Kuwait" => "KW",
    "Hong Kong" => "HK",
    "Taiwan" => "TW",
    "Macau" => "MO",
    "Iceland" => "IS",
    "Croatia" => "HR",
    "Czech Republic" => "CZ",
    "Czechia" => "CZ",
    "Hungary" => "HU",
    "Romania" => "RO",
    "Bulgaria" => "BG",
    "Morocco" => "MA",
    "Tunisia" => "TN",
    "Kenya" => "KE",
    "Ghana" => "GH",
    "Nigeria" => "NG",
    "Ethiopia" => "ET",
    "Tanzania" => "TZ",
    "Uganda" => "UG",
    "Cambodia" => "KH",
    "Laos" => "LA",
    "Myanmar" => "MM",
    "Bangladesh" => "BD",
    "Pakistan" => "PK",
    "Sri Lanka" => "LK",
    "Nepal" => "NP",
    "Maldives" => "MV",
    "Fiji" => "FJ",
    "Costa Rica" => "CR",
    "Panama" => "PA",
    "Ecuador" => "EC",
    "Bolivia" => "BO",
    "Uruguay" => "UY",
    "Paraguay" => "PY",
    "Venezuela" => "VE",
    "Cuba" => "CU",
    "Jamaica" => "JM",
    "Bahamas" => "BS",
    "Barbados" => "BB",
    "Trinidad and Tobago" => "TT",
    "Dominican Republic" => "DO",
    "Puerto Rico" => "PR",
    "Jordan" => "JO",
    "Lebanon" => "LB",
    "Oman" => "OM",
    "Bahrain" => "BH",
    "Azerbaijan" => "AZ",
    "Georgia" => "GE",
    "Armenia" => "AM",
    "Kazakhstan" => "KZ",
    "Uzbekistan" => "UZ",
    "Mongolia" => "MN",
    "Luxembourg" => "LU",
    "Slovenia" => "SI",
    "Slovakia" => "SK",
    "Estonia" => "EE",
    "Latvia" => "LV",
    "Lithuania" => "LT",
    "Malta" => "MT",
    "Cyprus" => "CY",
    "Albania" => "AL",
    "Serbia" => "RS",
    "Montenegro" => "ME",
    "Bosnia and Herzegovina" => "BA",
    "North Macedonia" => "MK",
    "Moldova" => "MD",
    "Belarus" => "BY",
    "Ukraine" => "UA"
  }.freeze

  class << self
    # Convert country name to ISO Alpha-2 code
    # @param country_name [String] Full country name
    # @return [String, nil] Two-letter ISO code or nil if not found
    def to_iso_code(country_name)
      return nil if country_name.blank?

      # Normalize the input
      normalized = country_name.to_s.strip

      # Try exact match first
      code = COUNTRY_CODES[normalized]
      return code if code

      # Try case-insensitive match
      COUNTRY_CODES.each do |name, code|
        return code if name.casecmp?(normalized)
      end

      # If no match found, log warning and return nil
      Rails.logger.warn "⚠️  Country code not found for: '#{country_name}'"
      nil
    end

    # Convert ISO code to country name
    # @param iso_code [String] Two-letter ISO code
    # @return [String, nil] Full country name or nil if not found
    def to_country_name(iso_code)
      return nil if iso_code.blank?

      normalized_code = iso_code.to_s.upcase.strip
      COUNTRY_CODES.invert[normalized_code]
    end

    # Check if a country code is valid
    # @param iso_code [String] Two-letter ISO code
    # @return [Boolean]
    def valid_code?(iso_code)
      return false if iso_code.blank?

      normalized_code = iso_code.to_s.upcase.strip
      COUNTRY_CODES.values.include?(normalized_code)
    end

    # Get all available country codes
    # @return [Hash] All country name => ISO code mappings
    def all_mappings
      COUNTRY_CODES
    end
  end
end
