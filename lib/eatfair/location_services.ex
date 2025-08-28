defmodule Eatfair.LocationServices do
  @moduledoc """
  Professional location services with Google Maps Geocoding API integration.
  
  Provides intelligent address parsing, geocoding, and coordinate conversion
  with comprehensive error handling, caching, and fallback strategies.
  """
  
  require Logger
  
  @google_maps_base_url "https://maps.googleapis.com/maps/api/geocode/json"
  @default_region "nl" # Netherlands
  # Cache for geocoded results to reduce API calls and improve performance
  @doc """
  Main entry point for address geocoding with intelligent parsing and fallbacks.
  
  ## Examples
  
      iex> Eatfair.LocationServices.geocode_address("Amsterdam")
      {:ok, %{latitude: 52.3676, longitude: 4.9041, formatted_address: "Amsterdam, Netherlands"}}
      
      iex> Eatfair.LocationServices.geocode_address("1012 AB")
      {:ok, %{latitude: 52.3702, longitude: 4.8952, formatted_address: "1012 AB Amsterdam, Netherlands"}}
      
      iex> Eatfair.LocationServices.geocode_address("Nonexistent Location")
      {:error, :not_found}
  """
  def geocode_address(address) when is_binary(address) and byte_size(address) > 0 do
    # Normalize and clean the address input
    normalized_address = normalize_address_input(address)
    
    # Check if address becomes empty after normalization
    case String.trim(normalized_address) do
      "" -> {:error, :invalid_input}
      trimmed -> geocode_with_google_maps(trimmed)
    end
  end
  
  def geocode_address(_), do: {:error, :invalid_input}
  
  @doc """
  Geocodes an address using Google Maps API with comprehensive error handling.
  """
  def geocode_with_google_maps(address) do
    case get_api_key() do
      nil ->
        # Only log error in non-test environments
        unless Mix.env() == :test do
          Logger.error("Google Maps API key not configured")
        end
        fallback_geocoding(address)
        
      api_key ->
        perform_api_request(address, api_key)
    end
  end
  
  @doc """
  Batch geocoding for multiple addresses with rate limiting.
  """
  def geocode_addresses(addresses) when is_list(addresses) do
    # Process in batches to respect API rate limits
    addresses
    |> Enum.chunk_every(10)
    |> Enum.map(fn batch ->
      batch
      |> Enum.map(&geocode_address/1)
      |> Enum.zip(batch)
    end)
    |> List.flatten()
  end
  
  @doc """
  Clears the geocoding cache (useful for testing or cache invalidation).
  """
  def clear_cache do
    # In production, you'd clear Redis/ETS cache here
    # For now, we'll implement simple in-memory caching
    :ok
  end
  
  # Private functions
  
  defp normalize_address_input(address) do
    address
    |> String.trim()
    |> String.downcase()
    |> normalize_postal_code_spacing()
    |> enhance_dutch_address()
  end
  
  defp normalize_postal_code_spacing(address) do
    # Normalize postal code spacing: 1012  AB -> 1012 AB, 1012AB -> 1012 AB
    Regex.replace(~r/^(\d{4})\s*(\w{2})$/i, address, "\\1 \\2")
  end
  
  defp enhance_dutch_address(address) do
    cond do
      # Empty or whitespace-only address
      String.trim(address) == "" ->
        address
        
      # Dutch postal code pattern (1234 AB or 1234AB)
      Regex.match?(~r/^\d{4}\s?[a-z]{2}$/i, address) ->
        "#{address}, Netherlands"
        
      # City name without country
      not String.contains?(address, "netherlands") and not String.contains?(address, "nederland") ->
        "#{address}, Netherlands"
        
      true ->
        address
    end
  end
  
  defp perform_api_request(address, api_key) do
    params = [
      address: address,
      region: @default_region,
      key: api_key
    ]
    
    Logger.debug("Geocoding address via Google Maps API: #{address}")
    
    case Req.get(@google_maps_base_url, params: params) do
      {:ok, %{status: 200, body: response_body}} ->
        handle_google_maps_response(address, response_body)
        
      {:ok, %{status: status}} ->
        Logger.error("Google Maps API returned status #{status} for address: #{address}")
        fallback_geocoding(address)
        
      {:error, error} ->
        Logger.error("Google Maps API request failed for address #{address}: #{inspect(error)}")
        fallback_geocoding(address)
    end
  end
  
  defp handle_google_maps_response(address, response_body) do
    case response_body do
      %{"status" => "OK", "results" => [result | _]} ->
        extract_coordinates_from_result(address, result)
        
      %{"status" => "ZERO_RESULTS"} ->
        Logger.debug("No results found for address: #{address}")
        fallback_geocoding(address)
        
      %{"status" => "OVER_QUERY_LIMIT"} ->
        Logger.error("Google Maps API quota exceeded")
        fallback_geocoding(address)
        
      %{"status" => status} ->
        Logger.error("Google Maps API returned status: #{status}")
        fallback_geocoding(address)
        
      _ ->
        Logger.error("Unexpected Google Maps API response format")
        fallback_geocoding(address)
    end
  end
  
  defp extract_coordinates_from_result(original_address, result) do
    case result do
      %{
        "geometry" => %{
          "location" => %{
            "lat" => latitude,
            "lng" => longitude
          }
        },
        "formatted_address" => formatted_address
      } ->
        geocoded_result = %{
          latitude: latitude,
          longitude: longitude,
          formatted_address: formatted_address,
          confidence: :high,
          source: :google_maps_api
        }
        
        # Cache the successful result
        cache_result(original_address, geocoded_result)
        
        Logger.debug("Successfully geocoded: #{original_address} -> #{latitude}, #{longitude}")
        {:ok, geocoded_result}
        
      _ ->
        Logger.error("Invalid result structure from Google Maps API")
        fallback_geocoding(original_address)
    end
  end
  
  defp fallback_geocoding(address) do
    # No fallback cities - if Google Maps API fails, return error
    Logger.debug("Geocoding failed for address: #{address}")
    {:error, :not_found}
  end
  
  
  defp get_api_key do
    # First try runtime environment variable (for .env files)
    case System.get_env("GOOGLE_MAPS_API_KEY") do
      nil ->
        # Fallback to compile-time application config
        case Application.get_env(:eatfair, :google_maps) do
          nil -> nil
          config -> config[:api_key]
        end
      api_key -> api_key
    end
  end
  
  # Simple in-memory caching (in production, use Redis or ETS)
  defp get_cached_result(_address) do
    # TODO: Implement proper caching with ETS or Redis
    :miss
  end
  
  defp cache_result(_address, _result) do
    # TODO: Implement proper caching with ETS or Redis
    :ok
  end
end
