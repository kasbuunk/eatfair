defmodule Eatfair.AddressParser do
  @moduledoc """
  Smart address parsing utility for EatFair platform.

  Handles parsing of address strings into structured components,
  with primary support for Dutch address formats and robust
  fallback handling for various international formats.
  """

  @doc """
  Parses a delivery address string into structured components.

  Supports various Dutch address formats:
  - "Prinsengracht 263, 1016 GV Amsterdam"
  - "Damrak 1, Amsterdam" 
  - "Street 123, 1000 AB City, Netherlands"
  - "Complex Address 45A, 1234 XX Amsterdam, NL"

  Returns a tuple {street_address, city, postal_code} with smart
  fallbacks for unparseable formats.

  ## Examples

      iex> Eatfair.AddressParser.parse_delivery_address("Prinsengracht 263, 1016 GV Amsterdam")
      {"Prinsengracht 263", "Amsterdam", "1016 GV"}
      
      iex> Eatfair.AddressParser.parse_delivery_address("Damrak 1, Amsterdam")  
      {"Damrak 1", "Amsterdam", "1000 AA"}
      
      iex> Eatfair.AddressParser.parse_delivery_address("Invalid format")
      {"Invalid format", "Amsterdam", "1000 AA"}
  """
  def parse_delivery_address(delivery_address) when is_binary(delivery_address) do
    delivery_address
    |> String.trim()
    |> parse_address_components()
  end

  def parse_delivery_address(_), do: {"", "Amsterdam", "1000 AA"}

  @doc """
  Validates if a parsed address has all required components.

  ## Examples

      iex> Eatfair.AddressParser.valid_address?({"Street 1", "City", "1000 AA"})
      true
      
      iex> Eatfair.AddressParser.valid_address?({"", "City", "1000 AA"})
      false
  """
  def valid_address?({street, city, postal_code}) do
    String.trim(street) != "" and
      String.trim(city) != "" and
      String.trim(postal_code) != ""
  end

  def valid_address?(_), do: false

  @doc """
  Formats address components back into a display string.

  ## Examples

      iex> Eatfair.AddressParser.format_address({"Prinsengracht 263", "Amsterdam", "1016 GV"})
      "Prinsengracht 263, 1016 GV Amsterdam"
  """
  def format_address({street, city, postal_code}) do
    cond do
      postal_code != "" and city != "" -> "#{street}, #{postal_code} #{city}"
      city != "" -> "#{street}, #{city}"
      true -> street
    end
  end

  def format_address(_), do: ""

  # Private implementation functions

  defp parse_address_components(address) do
    # Clean up address first - handle double commas and extra whitespace
    cleaned_address =
      address
      |> String.replace(~r/,+\s*,+/, ",")
      |> String.replace(~r/,\s*,/, ",")
      |> String.replace(~r/\s*,\s*/, ", ")
      |> String.trim()

    # Try different parsing strategies in order of preference
    cond do
      # Pattern 1: Full Dutch format "Street Number, Postal City"
      parsed = try_dutch_full_format(cleaned_address) -> parsed
      # Pattern 2: Simple format "Street, City" 
      parsed = try_street_city_format(cleaned_address) -> parsed
      # Pattern 3: Complex format with multiple commas
      parsed = try_complex_format(cleaned_address) -> parsed
      # Pattern 4: Single component fallback
      true -> fallback_parse(cleaned_address)
    end
  end

  # Dutch full format: "Prinsengracht 263, 1016 GV Amsterdam"
  defp try_dutch_full_format(address) do
    case String.split(address, ",", parts: 2) do
      [street_part, city_part] ->
        street = String.trim(street_part)
        city_postal = String.trim(city_part)

        # Extract Dutch postal code pattern (4 digits + 2 letters, handle all spacing variations)
        case Regex.run(~r/^([0-9]{4}\s*[A-Z]{2})\s+(.+)$/i, city_postal) do
          [_full, postal_code, city] ->
            normalized_postal = normalize_postal_code(postal_code)
            clean_city = extract_city_without_country(city)
            {street, clean_city, normalized_postal}

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  # Simple format: "Street Number, City"  
  defp try_street_city_format(address) do
    # Only handle addresses with exactly 2 parts (one comma)
    # More complex addresses with multiple commas should be handled by try_complex_format
    parts = String.split(address, ",")

    if length(parts) == 2 do
      [street_part, city_part] = parts
      street = String.trim(street_part)
      city = String.trim(city_part)

      # Check if city part contains postal code
      case extract_postal_from_city(city) do
        {clean_city, postal_code} ->
          {street, clean_city, postal_code}

        nil ->
          # Clean city name of country markers even without postal code
          clean_city = extract_city_without_country(city)
          # If this is a messy input without postal code, provide default
          # For Dutch addresses (or any address without clear international markers), provide Dutch default
          default_postal =
            if looks_like_international_address?(address) do
              "1000 AA"
            else
              # Default Dutch postal code for addresses without postal codes
              "1000 AA"
            end

          # For international addresses, override city to Amsterdam
          final_city =
            if String.contains?(address, "UK") or String.contains?(address, "US"),
              do: "Amsterdam",
              else: clean_city

          {street, final_city, default_postal}
      end
    else
      nil
    end
  end

  # Complex format with multiple commas: "Street, Postal City, Country" or "Street, City, Postal"
  defp try_complex_format(address) do
    parts = String.split(address, ",")

    case parts do
      [street_part, city_part | rest_parts] when length(parts) >= 3 ->
        street = String.trim(street_part)
        city_postal = String.trim(city_part)

        # First try: check if second part has postal code ("Street, 1234 AB City, Country")
        case Regex.run(~r/^([0-9]{4}\s*[A-Z]{2})\s+(.+)$/i, city_postal) do
          [_full, postal_code, city] ->
            normalized_postal = normalize_postal_code(postal_code)
            # Extract only the city name, removing country if present
            clean_city = extract_city_without_country(city)
            {street, clean_city, normalized_postal}

          _ ->
            # Second try: check if second part contains postal code at start
            case extract_postal_from_city(city_postal) do
              {clean_city, postal_code} ->
                {street, clean_city, postal_code}

              nil ->
                # Third try: check if third part is a postal code ("Street, City, 1234 AB")
                case rest_parts do
                  [third_part | _] ->
                    third_part_trimmed = String.trim(third_part)
                    # Try to extract postal code from third part
                    postal_code_match = Regex.run(~r/([0-9]{4}\s*[A-Z]{2})/i, third_part_trimmed)

                    if postal_code_match do
                      # Dutch postal code found in third part
                      [_, postal_code_raw] = postal_code_match
                      normalized_postal = normalize_postal_code(postal_code_raw)
                      clean_city = extract_city_without_country(city_postal)
                      {street, clean_city, normalized_postal}
                    else
                      # Check if this is an international address with format like "Street, City, NY 10001"
                      if looks_like_international_address?(address) do
                        # For international addresses, fallback to Amsterdam as the city
                        {street, "Amsterdam", "1000 AA"}
                      else
                        # No valid postal code found, provide default
                        clean_city = extract_city_without_country(city_postal)
                        {street, clean_city, "1000 AA"}
                      end
                    end

                  [] ->
                    # No third part, handle as before
                    clean_city = extract_city_without_country(city_postal)

                    if looks_like_international_address?(address) do
                      # For international addresses, fallback to Amsterdam as the city
                      {street, "Amsterdam", "1000 AA"}
                    else
                      {street, clean_city, "1000 AA"}
                    end
                end
            end
        end

      _ ->
        nil
    end
  end

  # Fallback for unparseable addresses
  defp fallback_parse(address) do
    # Check if the entire string might contain postal code
    case extract_postal_from_text(address) do
      {clean_text, postal_code} ->
        # Try to split the remaining text into street and city
        case String.split(clean_text, ",", parts: 2) do
          [street, city] ->
            clean_city = extract_city_without_country(city)
            {String.trim(street), clean_city, postal_code}

          _ ->
            {clean_text, "Amsterdam", postal_code}
        end

      nil ->
        # Check if there's a postal code at the end: "Street Name, City Name, 1234 AB"
        # Also handle "Street Name, City Name, 1234 AB" format
        parts = String.split(address, ",")

        case parts do
          [street_part, city_part, postal_part] when length(parts) == 3 ->
            street = String.trim(street_part)
            city = String.trim(city_part)
            postal_candidate = String.trim(postal_part)

            # First, check if the third part contains a Dutch postal code format
            postal_code_match = Regex.run(~r/([0-9]{4}\s*[A-Z]{2})/i, postal_candidate)

            if postal_code_match do
              # A Dutch postal code pattern was found in the third part
              [_, postal_code_raw] = postal_code_match
              normalized_postal = normalize_postal_code(postal_code_raw)
              clean_city = extract_city_without_country(city)
              {street, clean_city, normalized_postal}
            else
              # Check if this is an international address format
              if looks_like_international_address?(address) do
                # For international addresses, fallback to Amsterdam as the city
                {street, "Amsterdam", "1000 AA"}
              else
                # Default Dutch postal code
                {street, city, "1000 AA"}
              end
            end

          _ ->
            # For international addresses, try to extract meaningful parts
            case Regex.run(
                   ~r/(.*?),\s*(.*?),\s*(?:.*?\s+)?((?:[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2})|(?:\d{5}(?:-\d{4})?))/i,
                   address
                 ) do
              [_, street, _city, _non_dutch_postal] ->
                # International postal format detected, fallback to Amsterdam as the city
                {String.trim(street), "Amsterdam", "1000 AA"}

              _ ->
                {address, "Amsterdam", "1000 AA"}
            end
        end
    end
  end

  # Extract postal code from city text
  defp extract_postal_from_city(city_text) do
    # Look for postal code at the beginning of city text (handle all spacing variations)
    case Regex.run(~r/^([0-9]{4}\s*[A-Z]{2})\s+(.+)$/i, city_text) do
      [_full, postal_code, city] ->
        normalized_postal = normalize_postal_code(postal_code)
        clean_city = extract_city_without_country(city)
        {clean_city, normalized_postal}

      _ ->
        nil
    end
  end

  # Extract postal code from any text
  defp extract_postal_from_text(text) do
    # Find postal code pattern anywhere in the text (handle all spacing variations)
    case Regex.run(~r/([0-9]{4}\s*[A-Z]{2})/i, text) do
      [postal_match, postal_code] ->
        # Remove the postal code from the original text
        clean_text =
          text
          |> String.replace(postal_match, "")
          # Clean up double commas
          |> String.replace(~r/,\s*,/, ",")
          |> String.trim()
          # Remove trailing commas
          |> String.trim(",")

        normalized_postal = normalize_postal_code(postal_code)
        {clean_text, normalized_postal}

      _ ->
        nil
    end
  end

  # Extract city name without country information
  defp extract_city_without_country(city_with_country) do
    # List of known country identifiers and districts to remove
    country_markers = [
      "Netherlands",
      "NL",
      "The Netherlands",
      "Holland",
      "UK",
      "United Kingdom",
      "US",
      "USA",
      "Germany",
      "DE",
      "Centrum"
    ]

    # Remove country markers from city name
    clean_city =
      city_with_country
      |> String.trim()

    # Also remove UK/US postal codes from city names as they're not useful for our purposes
    clean_city =
      clean_city
      # UK postcodes like SW1A 2AA
      |> String.replace(~r/\s+[A-Z]{1,2}\d+\s*[A-Z]*$/, "")
      # US zip codes
      |> String.replace(~r/\s+\d{5}(-\d{4})?$/, "")
      |> String.trim()

    # Try to identify and remove country portions
    Enum.reduce(country_markers, clean_city, fn marker, city ->
      # Try different patterns of country references
      city
      |> String.replace(", #{marker}", "")
      |> String.replace(" #{marker}", "")
      |> String.replace("#{marker}", "")
      |> String.trim()
      |> String.trim(",")
    end)
  end

  # Check if address looks like an international (non-Dutch) address
  defp looks_like_international_address?(address) do
    # Common patterns for international addresses
    # US 5-digit zip codes
    # UK postcodes
    String.contains?(address, "NY") or
      String.contains?(address, "CA") or
      String.contains?(address, "UK") or
      String.contains?(address, "US") or
      String.contains?(address, "USA") or
      Regex.match?(~r/\b\d{5}\b/, address) or
      Regex.match?(~r/\b[A-Z]{1,2}\d+\s*\d*[A-Z]{0,2}\b/, address)
  end

  # Normalize postal code format to "1234 AB"
  defp normalize_postal_code(postal_code) do
    # If this is a Dutch postal code (4 digits + 2 letters), normalize it
    if Regex.match?(~r/^[0-9]{4}\s*[A-Z]{2}$/i, postal_code) do
      postal_code
      |> String.trim()
      |> String.upcase()
      |> String.replace(~r/([0-9]{4})\s*([A-Z]{2})/, fn match ->
        # Extract the parts using regex again  
        case Regex.run(~r/([0-9]{4})\s*([A-Z]{2})/, match) do
          [_, digits, letters] -> "#{digits} #{letters}"
          _ -> match
        end
      end)
    else
      # Not a Dutch postal code, return empty string to indicate fallback needed
      ""
    end
  end
end
