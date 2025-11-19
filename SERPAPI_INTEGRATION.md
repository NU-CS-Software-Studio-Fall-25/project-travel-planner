# SerpAPI Flight Integration

## Overview

This project now integrates with SerpAPI's Google Flights API to provide realistic flight pricing for travel recommendations. The system uses an iterative algorithm to find destinations that fit within the user's budget constraints.

## How It Works

### Architecture

1. **AirportLookupService** (`app/Services/airport_lookup_service.rb`)
   - Maps cities and locations to airport codes (IATA)
   - Supports major airports worldwide
   - Handles location parsing from Google Maps format

2. **SerpapiFlightService** (`app/Services/serpapi_flight_service.rb`)
   - Connects to SerpAPI Google Flights API
   - Fetches real-time flight prices
   - Returns flight details including duration, stops, and airline info

3. **OpenaiService** (Modified) (`app/Services/openai_service.rb`)
   - **NEW: Iterative Algorithm**
   - Step 1: Ask OpenAI for a destination city (not full plan)
   - Step 2: Query SerpAPI for actual flight prices
   - Step 3: Validate flight cost against budget (must be < 50% of max budget)
   - Step 4: If valid, request full travel plan from OpenAI with real flight data
   - Step 5: If invalid, reject and try again (max 3 attempts)

### Algorithm Flow

```
User submits preferences
    ↓
┌─────────────────────────────────┐
│ Iteration Loop (Max 3 attempts) │
└─────────────────────────────────┘
    ↓
1. OpenAI suggests a city
    ↓
2. SerpAPI checks flight prices
    ↓
3. Is flight < 50% of max budget?
    ├─ YES → Get full plan from OpenAI → Return to user ✓
    └─ NO → Add to rejected list → Loop again
    ↓
After 3 failed attempts:
    Return "No suitable destination" message with suggestions
```

## Configuration

### Environment Variables

Add your SerpAPI key to your environment:

```bash
# In your .env file or environment
SERPAPI_KEY=your_api_key_here
```

Current key (in code): `96e7a7f8814b6000ef60d17202cedca1b66d061c4024101b2dcb3152ffa33ff4`

### Budget Constraints

- **Flight Budget Threshold**: 50% of max budget
- **Max Iterations**: 3 attempts
- If no suitable destination found after 3 attempts, user receives helpful feedback

## API Endpoints Used

### SerpAPI Google Flights
- **Endpoint**: `https://serpapi.com/search?engine=google_flights`
- **Parameters**:
  - `departure_id`: IATA airport code (e.g., ORD, JFK)
  - `arrival_id`: IATA airport code (e.g., CDG, NRT)
  - `outbound_date`: YYYY-MM-DD format
  - `return_date`: YYYY-MM-DD format
  - `type`: 1 (round trip)
  - `adults`: Number of travelers
  - `currency`: USD
  - `travel_class`: 1 (economy)

## Testing

### Run SerpAPI Integration Test

```bash
rails runner test/services/serpapi_integration_test.rb
```

Tests:
- Airport lookup functionality
- SerpAPI flight price retrieval
- Data parsing and formatting

### Run Full Iterative Algorithm Test

```bash
rails runner test/services/openai_iterative_test.rb
```

Tests:
- Complete recommendation flow
- OpenAI + SerpAPI integration
- Budget validation
- Error handling

## Features

### Real-Time Flight Pricing
- Actual flight costs from Google Flights
- Includes airline, duration, and stop information
- Updates dynamically based on search dates

### Budget Validation
- Ensures flights don't exceed 50% of total budget
- Leaves adequate budget for accommodation, food, and activities
- Prevents unrealistic recommendations

### Iterative Optimization
- Automatically retries with different destinations
- Tracks rejected cities to avoid repeats
- Provides clear feedback if no suitable options found

### Airport Intelligence
- Automatically finds nearest airports for user's location
- Matches destination cities to appropriate airports
- **Multi-Airport Search**: For cities with multiple airports, checks up to 3 airports
- **Smart Prioritization**: Prioritizes international/major airports first
  - Example: JFK before LGA for New York
  - Example: LHR before Luton for London
- **Best Price Selection**: Compares prices across all available airports and returns cheapest option
- Handles 7,699+ airports worldwide from comprehensive dataset

## Error Handling

The system gracefully handles:
- API failures (SerpAPI or OpenAI)
- Missing airport data
- No flights available for route
- Budget constraints too restrictive
- Network timeouts

Error responses include:
- Clear error messages
- Rejected destinations with reasons
- Actionable suggestions for users

## Future Enhancements

Potential improvements:
- Cache flight prices for popular routes
- Support one-way and multi-city trips
- Allow flexible date searches (+/- 3 days)
- Include budget airlines filter
- Add flight class preferences (economy, business, first)

## Logging

The system provides detailed logging:
- SerpAPI request/response details
- Flight price validation results
- OpenAI iteration progress
- Rejected cities and reasons

Check logs with:
```bash
tail -f log/development.log
```

## Support

For issues or questions:
1. Check logs for detailed error messages
2. Verify SerpAPI key is valid
3. Ensure OpenAI API key is configured
4. Test individual services with provided test scripts
