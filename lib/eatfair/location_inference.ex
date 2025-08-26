defmodule Eatfair.LocationInference do
  @moduledoc """
  Intelligent location inference system that combines multiple data sources
  to provide the best possible location prefill for users.
  
  Data sources in priority order:
  1. Authenticated user's saved address
  2. Previous session data from location searches
  3. Browser geolocation (requested once per session, on user cue)
  4. IP-based location estimation
  5. Browser country/language inference
  """

  alias Eatfair.Accounts

  @doc """
  Infers the best location for a user based on available data sources.
  
  Returns a map with:
  - address: String address for prefill
  - confidence: :high | :medium | :low
  - source: The data source used
  """
  def infer_location(socket) do
    cond do
      user_address = get_user_saved_address(socket) ->
        %{
          address: format_address(user_address),
          confidence: :high,
          source: :user_profile
        }
      
      session_address = get_session_address(socket) ->
        %{
          address: session_address,
          confidence: :medium,
          source: :session_data
        }
      
      browser_location = get_browser_location(socket) ->
        %{
          address: browser_location,
          confidence: :medium,
          source: :browser_geolocation
        }
      
      ip_location = get_ip_location(socket) ->
        %{
          address: ip_location,
          confidence: :low,
          source: :ip_geolocation
        }
      
      true ->
        %{
          address: "",
          confidence: :none,
          source: :none
        }
    end
  end

  @doc """
  Stores a location search in the session for future inference.
  """
  def store_session_location(socket, address) do
    case socket do
      %{assigns: assigns} ->
        %{socket | assigns: Map.put(assigns, :session_location, address)}
      _ ->
        socket
    end
  end

  @doc """
  Gets the stored session location if available.
  """
  def get_session_location(socket) do
    socket.assigns[:session_location]
  end

  @doc """
  Formats a user address for display in the location input field.
  """
  def format_address(address) do
    parts = [
      address.street_address,
      address.city,
      address.postal_code
    ]
    |> Enum.filter(&(&1 && String.trim(&1) != ""))
    
    case parts do
      [] -> ""
      [city] -> city
      _ -> Enum.join(parts, ", ")
    end
  end

  @doc """
  Checks if browser geolocation should be requested.
  Returns true only if it hasn't been requested this session.
  """
  def should_request_geolocation?(socket) do
    not Map.get(socket.assigns, :geolocation_requested, false)
  end

  @doc """
  Marks that geolocation has been requested for this session.
  """
  def mark_geolocation_requested(socket) do
    case socket do
      %{assigns: assigns} ->
        %{socket | assigns: Map.put(assigns, :geolocation_requested, true)}
      _ ->
        socket
    end
  end

  # Private functions

  defp get_user_saved_address(socket) do
    case socket.assigns[:current_scope] do
      %{user: %{id: user_id}} ->
        addresses = Accounts.list_user_addresses(user_id)
        Enum.find(addresses, & &1.is_default) || List.first(addresses)
      
      _ ->
        nil
    end
  end

  defp get_session_address(socket) do
    socket.assigns[:session_location]
  end

  defp get_browser_location(socket) do
    # Check if we have browser geolocation data in session
    socket.assigns[:browser_location]
  end

  defp get_ip_location(socket) do
    # Simple IP-based location inference
    # In production, this would call a geolocation service
    # For now, we'll use a simple fallback
    case get_request_headers(socket) do
      headers when is_list(headers) ->
        # Look for common country/location headers
        case find_location_from_headers(headers) do
          nil -> get_default_location_by_language(socket)
          location -> location
        end
      _ -> 
        get_default_location_by_language(socket)
    end
  end

  defp get_request_headers(socket) do
    # Try to get request headers from socket context
    case socket.assigns[:__changed__] do
      %{} -> nil
      _ -> nil
    end
  end

  defp find_location_from_headers(_headers) do
    # In production, parse CF-IPCountry, X-Forwarded-For, etc.
    # For MVP, return nil to fall back to language detection
    nil
  end

  defp get_default_location_by_language(_socket) do
    # For MVP, default to Amsterdam as it's a Dutch platform
    # In production, this could check Accept-Language headers
    "Amsterdam"
  end
end
