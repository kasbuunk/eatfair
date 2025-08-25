defmodule Eatfair.GeoUtils do
  @moduledoc """
  Geographic utility functions for distance calculations and location-based features.
  """

  @earth_radius_km 6371.0

  @doc """
  Calculates the great-circle distance between two points on Earth using the Haversine formula.

  ## Parameters
  - lat1: Latitude of the first point (in decimal degrees)
  - lon1: Longitude of the first point (in decimal degrees)  
  - lat2: Latitude of the second point (in decimal degrees)
  - lon2: Longitude of the second point (in decimal degrees)

  ## Returns
  Distance in kilometers as a float.

  ## Examples

      iex> Eatfair.GeoUtils.haversine_distance(52.3702, 4.9002, 52.3812, 4.9041)
      1.234
  """
  def haversine_distance(lat1, lon1, lat2, lon2) do
    # Convert decimal degrees to radians
    lat1_rad = to_radians(lat1)
    lon1_rad = to_radians(lon1)
    lat2_rad = to_radians(lat2)
    lon2_rad = to_radians(lon2)

    # Calculate differences
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    # Haversine formula
    a =
      :math.sin(dlat / 2) * :math.sin(dlat / 2) +
        :math.cos(lat1_rad) * :math.cos(lat2_rad) *
          :math.sin(dlon / 2) * :math.sin(dlon / 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    # Distance in kilometers
    @earth_radius_km * c
  end

  @doc """
  Calculates distance between two points using Decimal coordinates.
  Accepts Decimal types and converts them to floats for calculation.

  ## Examples

      iex> lat1 = Decimal.new("52.3702")
      iex> lon1 = Decimal.new("4.9002") 
      iex> lat2 = Decimal.new("52.3812")
      iex> lon2 = Decimal.new("4.9041")
      iex> Eatfair.GeoUtils.distance_decimal(lat1, lon1, lat2, lon2)
      1.234
  """
  def distance_decimal(lat1, lon1, lat2, lon2) do
    lat1_float = Decimal.to_float(lat1)
    lon1_float = Decimal.to_float(lon1)
    lat2_float = Decimal.to_float(lat2)
    lon2_float = Decimal.to_float(lon2)

    haversine_distance(lat1_float, lon1_float, lat2_float, lon2_float)
  end

  @doc """
  Checks if a restaurant is within delivery range of a given location.

  ## Parameters
  - restaurant_lat: Restaurant latitude (Decimal or float)
  - restaurant_lon: Restaurant longitude (Decimal or float)
  - customer_lat: Customer latitude (Decimal or float)  
  - customer_lon: Customer longitude (Decimal or float)
  - delivery_radius_km: Maximum delivery distance in kilometers

  ## Returns
  Boolean indicating if delivery is available.
  """
  def within_delivery_range?(
        restaurant_lat,
        restaurant_lon,
        customer_lat,
        customer_lon,
        delivery_radius_km
      ) do
    distance =
      case {restaurant_lat, restaurant_lon, customer_lat, customer_lon} do
        {%Decimal{}, %Decimal{}, %Decimal{}, %Decimal{}} ->
          distance_decimal(restaurant_lat, restaurant_lon, customer_lat, customer_lon)

        _ ->
          haversine_distance(restaurant_lat, restaurant_lon, customer_lat, customer_lon)
      end

    distance <= delivery_radius_km
  end

  @doc """
  Geocodes a simple address string to approximate coordinates for testing purposes.
  This is a basic implementation for development/testing. In production, you would
  use a proper geocoding service like Google Maps API or OpenStreetMap Nominatim.

  ## Examples

      iex> Eatfair.GeoUtils.geocode_address("Amsterdam, Netherlands")
      {:ok, %{latitude: 52.3676, longitude: 4.9041}}
      
      iex> Eatfair.GeoUtils.geocode_address("Unknown Location")
      {:error, :not_found}
  """
  def geocode_address(address) when is_binary(address) do
    # Simple geocoding for common test locations
    # In production, this would call a real geocoding API
    address_lower = String.downcase(address)

    cond do
      String.contains?(address_lower, "amsterdam") ->
        {:ok, %{latitude: 52.3676, longitude: 4.9041}}

      String.contains?(address_lower, "utrecht") ->
        {:ok, %{latitude: 52.0907, longitude: 5.1214}}

      String.contains?(address_lower, "damrak") ->
        {:ok, %{latitude: 52.3702, longitude: 4.8952}}

      String.contains?(address_lower, "nieuwmarkt") ->
        {:ok, %{latitude: 52.3720, longitude: 4.9002}}

      String.contains?(address_lower, "prinsengracht") ->
        {:ok, %{latitude: 52.3738, longitude: 4.8840}}

      String.contains?(address_lower, "herengracht") ->
        {:ok, %{latitude: 52.3707, longitude: 4.8897}}

      String.contains?(address_lower, "amstelpark") ->
        {:ok, %{latitude: 52.3400, longitude: 4.8900}}

      true ->
        {:error, :not_found}
    end
  end

  @doc """
  Alias for haversine_distance/4 with consistent naming.
  Used by courier tracking system for ETA calculations.

  ## Parameters
  - lat1: Latitude of the first point (float)
  - lon1: Longitude of the first point (float)
  - lat2: Latitude of the second point (float)  
  - lon2: Longitude of the second point (float)

  ## Returns
  Distance in kilometers as a float.
  """
  def calculate_distance(lat1, lon1, lat2, lon2) do
    haversine_distance(lat1, lon1, lat2, lon2)
  end

  defp to_radians(degrees) do
    degrees * :math.pi() / 180.0
  end
end
