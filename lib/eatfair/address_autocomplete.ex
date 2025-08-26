defmodule Eatfair.AddressAutocomplete do
  @moduledoc """
  Dutch address autocomplete system using postal code + street number approach.
  
  The Netherlands has a very structured address system:
  - Postal code (6 characters: 4 digits + 2 letters, e.g. "1012AB")
  - Street number (with optional suffix, e.g. "123", "123A", "123-1")
  - This combination uniquely identifies most addresses
  
  For MVP, we implement a simple lookup system. In production, this would
  integrate with services like:
  - PostNL Adresservice
  - BAG (Basisregistraties Adressen en Gebouwen) 
  - pdok.nl API
  - Google Places API with Dutch focus
  """

  @doc """
  Suggests Dutch addresses based on partial input.
  
  Supports various input formats:
  - Postal code: "1012" -> suggests addresses in that area
  - Postal code + letters: "1012AB" -> suggests street addresses 
  - Street name: "Dam" -> suggests streets with that name
  - Combined: "Dam 1" -> suggests specific addresses
  """
  def suggest_addresses(query) when is_binary(query) do
    normalized_query = String.downcase(String.trim(query))
    
    cond do
      # Full postal code pattern (1234AB)
      Regex.match?(~r/^\d{4}[a-z]{2}$/, normalized_query) ->
        suggest_by_postal_code(normalized_query)
      
      # Partial postal code (1234)
      Regex.match?(~r/^\d{4}$/, normalized_query) ->
        suggest_by_partial_postal_code(normalized_query)
      
      # Street name or address
      String.length(normalized_query) >= 2 ->
        suggest_by_street_name(normalized_query)
      
      true ->
        []
    end
  end

  @doc """
  Validates and formats a Dutch address.
  Returns formatted address with coordinates if valid.
  """
  def validate_address(postal_code, street_number, street_name \\ nil) do
    with {:ok, formatted_postal_code} <- validate_postal_code(postal_code),
         {:ok, formatted_number} <- validate_street_number(street_number),
         {:ok, address_info} <- lookup_address(formatted_postal_code, formatted_number, street_name) do
      {:ok, format_address_result(address_info)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Parses a free-form address string into components.
  Handles various Dutch address formats.
  """
  def parse_address_string(address_string) do
    normalized = String.trim(address_string)
    
    # Try different parsing patterns
    cond do
      # Pattern: "Street Name 123, 1234AB City"
      match = Regex.run(~r/^(.+?)\s+(\d+[a-z]?(?:-\d+)?),\s*(\d{4}[a-z]{2})\s+(.+)$/i, normalized) ->
        [_, street_name, number, postal_code, city] = match
        %{
          street_name: String.trim(street_name),
          street_number: String.trim(number),
          postal_code: String.upcase(String.trim(postal_code)),
          city: String.trim(city)
        }
      
      # Pattern: "1234AB 123" (postal code + number)
      match = Regex.run(~r/^(\d{4}[a-z]{2})\s+(\d+[a-z]?(?:-\d+)?)$/i, normalized) ->
        [_, postal_code, number] = match
        %{
          postal_code: String.upcase(String.trim(postal_code)),
          street_number: String.trim(number),
          street_name: nil,
          city: nil
        }
      
      # Pattern: "Street Name 123" 
      match = Regex.run(~r/^(.+?)\s+(\d+[a-z]?(?:-\d+)?)$/i, normalized) ->
        [_, street_name, number] = match
        %{
          street_name: String.trim(street_name),
          street_number: String.trim(number),
          postal_code: nil,
          city: nil
        }
      
      # Just postal code
      Regex.match?(~r/^\d{4}[a-z]{2}$/i, normalized) ->
        %{
          postal_code: String.upcase(normalized),
          street_number: nil,
          street_name: nil,
          city: nil
        }
      
      true ->
        # Free text - treat as street name or city
        %{
          street_name: nil,
          street_number: nil,
          postal_code: nil,
          city: normalized
        }
    end
  end

  # Private functions for MVP implementation
  # In production, these would call real APIs

  defp suggest_by_postal_code(postal_code) do
    # Mock data for common Amsterdam postal codes for MVP
    mock_addresses = %{
      "1012ab" => [
        %{
          display: "Dam 1, 1012AB Amsterdam",
          postal_code: "1012AB",
          street_name: "Dam",
          street_number: "1",
          city: "Amsterdam",
          latitude: 52.3738,
          longitude: 4.8910
        }
      ],
      "1015dz" => [
        %{
          display: "Prinsengracht 100, 1015DZ Amsterdam", 
          postal_code: "1015DZ",
          street_name: "Prinsengracht",
          street_number: "100",
          city: "Amsterdam",
          latitude: 52.3738,
          longitude: 4.8840
        }
      ],
      "1016bs" => [
        %{
          display: "Herengracht 200, 1016BS Amsterdam",
          postal_code: "1016BS", 
          street_name: "Herengracht",
          street_number: "200",
          city: "Amsterdam",
          latitude: 52.3707,
          longitude: 4.8897
        }
      ]
    }
    
    Map.get(mock_addresses, postal_code, [])
  end

  defp suggest_by_partial_postal_code(partial) do
    # Suggest areas based on partial postal code
    area_suggestions = %{
      "1012" => [
        %{display: "1012AB Amsterdam Centrum", postal_code: "1012AB", city: "Amsterdam"},
        %{display: "1012JS Amsterdam Centrum", postal_code: "1012JS", city: "Amsterdam"}
      ],
      "1015" => [
        %{display: "1015DZ Amsterdam Jordaan", postal_code: "1015DZ", city: "Amsterdam"}
      ],
      "1016" => [
        %{display: "1016BS Amsterdam Grachtengordel", postal_code: "1016BS", city: "Amsterdam"}
      ],
      "3521" => [
        %{display: "3521CV Utrecht Centrum", postal_code: "3521CV", city: "Utrecht"}
      ]
    }
    
    Map.get(area_suggestions, partial, [])
  end

  defp suggest_by_street_name(query) do
    # Mock street name suggestions for MVP
    street_suggestions = [
      %{display: "Dam, Amsterdam", street_name: "Dam", city: "Amsterdam"},
      %{display: "Damrak, Amsterdam", street_name: "Damrak", city: "Amsterdam"},
      %{display: "Prinsengracht, Amsterdam", street_name: "Prinsengracht", city: "Amsterdam"},
      %{display: "Herengracht, Amsterdam", street_name: "Herengracht", city: "Amsterdam"},
      %{display: "Nieuwmarkt, Amsterdam", street_name: "Nieuwmarkt", city: "Amsterdam"},
      %{display: "Amsterdamsestraatweg, Utrecht", street_name: "Amsterdamsestraatweg", city: "Utrecht"}
    ]
    
    street_suggestions
    |> Enum.filter(fn suggestion ->
      String.contains?(String.downcase(suggestion.display), query)
    end)
    |> Enum.take(5)
  end

  defp validate_postal_code(postal_code) when is_binary(postal_code) do
    normalized = postal_code |> String.trim() |> String.upcase()
    
    if Regex.match?(~r/^\d{4}[A-Z]{2}$/, normalized) do
      {:ok, normalized}
    else
      {:error, "Invalid Dutch postal code format. Expected format: 1234AB"}
    end
  end

  defp validate_street_number(number) when is_binary(number) do
    normalized = String.trim(number)
    
    if Regex.match?(~r/^\d+[A-Za-z]?(?:-\d+)?$/, normalized) do
      {:ok, normalized}
    else
      {:error, "Invalid street number format"}
    end
  end

  defp lookup_address(postal_code, street_number, _street_name) do
    # Mock lookup for MVP - in production this would call BAG API or similar
    mock_data = %{
      {"1012AB", "1"} => %{
        street_name: "Dam",
        city: "Amsterdam",
        latitude: 52.3738,
        longitude: 4.8910
      },
      {"1015DZ", "100"} => %{
        street_name: "Prinsengracht", 
        city: "Amsterdam",
        latitude: 52.3738,
        longitude: 4.8840
      },
      {"1016BS", "200"} => %{
        street_name: "Herengracht",
        city: "Amsterdam", 
        latitude: 52.3707,
        longitude: 4.8897
      }
    }
    
    case Map.get(mock_data, {postal_code, street_number}) do
      nil -> {:error, "Address not found"}
      address_info -> {:ok, Map.merge(address_info, %{postal_code: postal_code, street_number: street_number})}
    end
  end

  defp format_address_result(address_info) do
    %{
      formatted_address: "#{address_info.street_name} #{address_info.street_number}, #{address_info.postal_code} #{address_info.city}",
      street_name: address_info.street_name,
      street_number: address_info.street_number,
      postal_code: address_info.postal_code,
      city: address_info.city,
      latitude: address_info.latitude,
      longitude: address_info.longitude
    }
  end
end
