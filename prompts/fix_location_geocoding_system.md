# Fix EatFair Location Geocoding System - Intelligent Address-to-Coordinates Conversion

## Problem Statement

The current location handling in EatFair has a fundamental architectural flaw that makes it completely unacceptable for production use. When users enter addresses on the homepage, the system navigates to the restaurants page with a location query parameter, but reports that "location is not found" because **the location data structure is fundamentally misaligned**.

### Critical Issues Identified

1. **Naive String-Based Location Queries**: The current system treats location as a simple string to be queried in the database, when location should be a pair of coordinates underneath the hood.

2. **Missing Intelligent Address Parsing**: Users expect to type something that resembles an address and have the intelligent system compensate by converting that into coordinates. This is completely missing.

3. **Broken User Experience**: Users enter "Amsterdam" or "Hilversum" and get "location not found" errors, making the entire restaurant discovery flow unusable.

4. **Mock Geocoding Service**: The current `GeoUtils.geocode_address/1` is a hard-coded mock that only handles a few specific city names with fixed coordinates.

## Current Implementation Analysis

### Homepage Flow (Working)
- User enters address in homepage form
- Form navigates to `/restaurants?location=<address>` (e.g., `/restaurants?location=hilversum`)
- Location parameter is passed correctly

### Discovery Page Issue (Broken)
- `EatfairWeb.RestaurantLive.Discovery.handle_params/3` receives location parameter
- Calls `apply_location_filter/2` with the address string
- `apply_location_filter/2` calls `Eatfair.GeoUtils.geocode_address(address)`
- **FAILURE POINT**: Mock geocoding only handles exact matches for "amsterdam", "utrecht", etc.
- When geocoding returns `{:error, :not_found}`, no restaurants are filtered
- User sees all restaurants but gets "Could not find location" error flash

### Current Mock Geocoding Service
```elixir
def geocode_address(address) when is_binary(address) do
  address_lower = String.downcase(address)
  
  cond do
    String.contains?(address_lower, "amsterdam") ->
      {:ok, %{latitude: 52.3676, longitude: 4.9041}}
    String.contains?(address_lower, "utrecht") ->
      {:ok, %{latitude: 52.0907, longitude: 5.1214}}
    # ... only 6 more hardcoded cities
    true ->
      {:error, :not_found}  # THIS BREAKS EVERYTHING
  end
end
```

## Specification Requirements

From the product specification, the system should provide:

1. **Immediate Location Detection**: Postal/zip code input, browser geolocation, IP fallback, Amsterdam Central Station default
2. **Intelligent Restaurant Discovery**: Location-based relevance scoring that prioritizes nearby restaurants
3. **Real-time Search Results**: Updates when location changes
4. **Complete Exclusion**: Irrelevant far-away restaurants should not appear
5. **Pre-filled Location Data**: For authenticated users
6. **Geographic Map Interface**: Restaurant pins with cuisine type and direct links

## Required Solution Architecture

### 1. Professional Geocoding Service Integration

Replace the mock geocoding service with a real geocoding API:

**Recommended Options:**
- **Google Maps Geocoding API** (most accurate for addresses)
- **OpenStreetMap Nominatim** (free, open source)
- **Mapbox Geocoding API** (developer-friendly)
- **Azure Maps** or **AWS Location Service** (enterprise options)

### 2. Intelligent Address Parsing Pipeline

Create a robust address parsing system that:

```elixir
defmodule Eatfair.LocationServices do
  @doc """
  Intelligent address parsing that handles:
  - Full addresses: "Prinsengracht 263, 1016 GV Amsterdam"
  - Postal codes: "1016 GV" 
  - City names: "Amsterdam", "Utrecht", "Rotterdam"
  - Partial addresses: "Prinsengracht, Amsterdam"
  - Fuzzy matching: "Amsteram", "Amsterdm"
  - International formats with graceful degradation
  """
  def parse_and_geocode(address_input) do
    address_input
    |> normalize_address()
    |> attempt_geocoding()
    |> handle_geocoding_result()
  end
  
  defp normalize_address(input) do
    # Clean, standardize, and enhance address input
  end
  
  defp attempt_geocoding(normalized_address) do
    # Try multiple geocoding strategies with fallbacks
  end
  
  defp handle_geocoding_result(result) do
    # Provide intelligent fallbacks and error handling
  end
end
```

### 3. Enhanced Location Data Model

Upgrade the location handling to support:
- Confidence levels (exact match, fuzzy match, fallback)
- Multiple coordinate systems if needed
- Caching of geocoded results
- Fallback coordinates for known regions

### 4. Robust Error Handling and Fallbacks

Instead of failing with "location not found":
- Attempt fuzzy matching for common typos
- Provide nearest major city as fallback
- Show "showing restaurants near [fallback location]" messaging
- Allow users to refine their search

### 5. Performance Optimization

- Cache geocoded results to avoid repeated API calls
- Implement rate limiting for external APIs
- Consider background geocoding for popular addresses
- Provide instant results for cached locations

## Test Cases to Validate

The solution should handle these real-world scenarios:

```elixir
# Exact city names
"Amsterdam" -> {52.3676, 4.9041}
"Utrecht" -> {52.0907, 5.1214}
"Rotterdam" -> {51.9225, 4.47917}

# Dutch postal codes
"1012 AB" -> Amsterdam coordinates
"3511 LX" -> Utrecht coordinates
"1016 GV" -> Amsterdam coordinates

# Full addresses
"Prinsengracht 263, 1016 GV Amsterdam" -> exact coordinates
"Damrak 70, Amsterdam" -> exact coordinates

# Fuzzy matching
"Amsteram" -> Amsterdam coordinates (typo correction)
"Utrech" -> Utrecht coordinates
"Hilversum" -> Hilversum coordinates

# Partial addresses
"Amsterdam Central" -> Amsterdam coordinates
"Schiphol" -> Airport coordinates

# International addresses (graceful degradation)
"London" -> Error with helpful message
"New York" -> Error with helpful message
```

## Implementation Priority

### Phase 1: Critical Fix (Immediate)
1. Integrate real geocoding service (Google Maps or Nominatim)
2. Replace mock service with API calls
3. Add proper error handling with fallbacks
4. Test with common Dutch cities and addresses

### Phase 2: Enhanced Intelligence (Short-term)
1. Add fuzzy matching for typos
2. Implement postal code lookup
3. Add result caching
4. Enhanced error messaging

### Phase 3: Advanced Features (Medium-term)
1. Geographic map interface
2. Real-time location updates
3. Browser geolocation integration
4. International address support

## External Resources Needed

To implement this solution, research and integrate:

1. **Geocoding API Documentation**:
   - Google Maps Geocoding API setup and usage
   - OpenStreetMap Nominatim API documentation
   - Rate limits, pricing, and terms of service
   - Authentication and API key management

2. **Dutch Address Standards**:
   - Official Dutch postal code format (4 digits + 2 letters)
   - Address formatting conventions
   - Common address abbreviations and variations

3. **Error Handling Best Practices**:
   - Graceful degradation strategies
   - User-friendly error messaging
   - Fallback location selection algorithms

4. **Performance Optimization**:
   - Caching strategies for geocoded results
   - Rate limiting implementations
   - Background processing patterns

## Success Criteria

The solution will be considered successful when:

1. **Users can enter any Dutch address** (city, postal code, or full address) and get relevant restaurant results
2. **Typos and variations are handled gracefully** with fuzzy matching
3. **Geographic filtering works accurately** showing only restaurants within delivery range
4. **Performance is acceptable** with sub-second response times for cached results
5. **Error messages are helpful** guiding users to successful searches
6. **International addresses degrade gracefully** with clear messaging about supported regions

## Current Technical Context

- **Framework**: Phoenix LiveView with Elixir
- **Database**: PostgreSQL with existing restaurant location data (latitude/longitude)
- **Current User Flow**: Homepage → `/restaurants?location=<address>` → Discovery page
- **Delivery System**: Working distance-based delivery radius calculations using Haversine formula
- **Address Management**: Users can save addresses with coordinate assignment

The core infrastructure is solid - only the geocoding service needs intelligent replacement to make the entire system work as intended.

---

**This is a critical production blocker that needs immediate attention. The current mock geocoding service makes location-based restaurant discovery completely unusable for real users.**
