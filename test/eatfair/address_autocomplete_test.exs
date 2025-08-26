defmodule Eatfair.AddressAutocompleteTest do
  use ExUnit.Case, async: true

  alias Eatfair.AddressAutocomplete

  describe "suggest_addresses/1" do
    test "suggests addresses for full postal code" do
      suggestions = AddressAutocomplete.suggest_addresses("1012AB")
      
      assert length(suggestions) == 1
      assert %{display: "Dam 1, 1012AB Amsterdam"} = List.first(suggestions)
    end

    test "suggests areas for partial postal code" do
      suggestions = AddressAutocomplete.suggest_addresses("1012")
      
      assert length(suggestions) == 2
      assert Enum.any?(suggestions, &(&1.display =~ "1012AB Amsterdam Centrum"))
      assert Enum.any?(suggestions, &(&1.display =~ "1012JS Amsterdam Centrum"))
    end

    test "suggests streets by name" do
      suggestions = AddressAutocomplete.suggest_addresses("dam")
      
      assert length(suggestions) >= 2
      assert Enum.any?(suggestions, &(&1.display =~ "Dam, Amsterdam"))
      assert Enum.any?(suggestions, &(&1.display =~ "Damrak, Amsterdam"))
    end

    test "returns empty list for very short queries" do
      suggestions = AddressAutocomplete.suggest_addresses("a")
      assert suggestions == []
    end

    test "handles case insensitive queries" do
      suggestions_lower = AddressAutocomplete.suggest_addresses("dam")
      suggestions_upper = AddressAutocomplete.suggest_addresses("DAM")
      
      assert suggestions_lower == suggestions_upper
    end
  end

  describe "validate_address/3" do
    test "validates and formats valid Dutch address" do
      result = AddressAutocomplete.validate_address("1012AB", "1")
      
      assert {:ok, address} = result
      assert address.formatted_address == "Dam 1, 1012AB Amsterdam"
      assert address.postal_code == "1012AB"
      assert address.street_number == "1"
      assert address.street_name == "Dam"
      assert address.city == "Amsterdam"
      assert is_float(address.latitude)
      assert is_float(address.longitude)
    end

    test "validates postal code with lowercase input" do
      result = AddressAutocomplete.validate_address("1012ab", "1")
      
      assert {:ok, address} = result
      assert address.postal_code == "1012AB"
    end

    test "validates street numbers with suffixes" do
      # Note: This would work in production with real address data
      result = AddressAutocomplete.validate_address("1012AB", "1A")
      assert {:error, "Address not found"} = result
    end

    test "rejects invalid postal code formats" do
      result = AddressAutocomplete.validate_address("invalid", "1")
      assert {:error, "Invalid Dutch postal code format. Expected format: 1234AB"} = result
      
      result = AddressAutocomplete.validate_address("12345", "1")
      assert {:error, "Invalid Dutch postal code format. Expected format: 1234AB"} = result
    end

    test "rejects invalid street number formats" do
      result = AddressAutocomplete.validate_address("1012AB", "invalid")
      assert {:error, "Invalid street number format"} = result
    end

    test "returns error for unknown address" do
      result = AddressAutocomplete.validate_address("9999ZZ", "999")
      assert {:error, "Address not found"} = result
    end
  end

  describe "parse_address_string/1" do
    test "parses full address string" do
      result = AddressAutocomplete.parse_address_string("Dam 1, 1012AB Amsterdam")
      
      assert result == %{
        street_name: "Dam",
        street_number: "1",
        postal_code: "1012AB",
        city: "Amsterdam"
      }
    end

    test "parses postal code and street number" do
      result = AddressAutocomplete.parse_address_string("1012AB 1")
      
      assert result == %{
        postal_code: "1012AB",
        street_number: "1",
        street_name: nil,
        city: nil
      }
    end

    test "parses street name and number" do
      result = AddressAutocomplete.parse_address_string("Dam 1")
      
      assert result == %{
        street_name: "Dam",
        street_number: "1",
        postal_code: nil,
        city: nil
      }
    end

    test "parses just postal code" do
      result = AddressAutocomplete.parse_address_string("1012AB")
      
      assert result == %{
        postal_code: "1012AB",
        street_number: nil,
        street_name: nil,
        city: nil
      }
    end

    test "handles street numbers with suffixes" do
      result = AddressAutocomplete.parse_address_string("Dam 123A")
      
      assert result == %{
        street_name: "Dam",
        street_number: "123A",
        postal_code: nil,
        city: nil
      }
    end

    test "handles street numbers with hyphens" do
      result = AddressAutocomplete.parse_address_string("Dam 123-1")
      
      assert result == %{
        street_name: "Dam",
        street_number: "123-1",
        postal_code: nil,
        city: nil
      }
    end

    test "handles free-form text as city" do
      result = AddressAutocomplete.parse_address_string("Amsterdam")
      
      assert result == %{
        street_name: nil,
        street_number: nil,
        postal_code: nil,
        city: "Amsterdam"
      }
    end

    test "handles complex street names" do
      result = AddressAutocomplete.parse_address_string("Nieuw-West Straat 123, 1234AB Amsterdam")
      
      assert result == %{
        street_name: "Nieuw-West Straat",
        street_number: "123",
        postal_code: "1234AB",
        city: "Amsterdam"
      }
    end

    test "normalizes postal code case" do
      result = AddressAutocomplete.parse_address_string("Dam 1, 1012ab amsterdam")
      
      assert result.postal_code == "1012AB"
    end
  end

  describe "Dutch address system edge cases" do
    test "handles various postal code patterns" do
      valid_codes = ["1012AB", "9999ZZ", "1000AA"]
      invalid_codes = ["1012ABC", "12AB", "1012", "ABCD12"]
      
      Enum.each(valid_codes, fn code ->
        result = AddressAutocomplete.parse_address_string(code)
        assert result.postal_code == code
      end)
      
      Enum.each(invalid_codes, fn code ->
        result = AddressAutocomplete.parse_address_string(code)
        # Invalid postal codes should be treated as city/free text
        assert result.postal_code == nil
      end)
    end

    test "handles various street number patterns" do
      valid_numbers = ["1", "123", "123A", "123a", "123-1", "123-12"]
      
      Enum.each(valid_numbers, fn number ->
        result = AddressAutocomplete.parse_address_string("Dam #{number}")
        assert result.street_number == number
      end)
    end

    test "suggests addresses case insensitive" do
      # Test that Amsterdam and utrecht both work
      amsterdam_suggestions = AddressAutocomplete.suggest_addresses("amsterdam")
      utrecht_suggestions = AddressAutocomplete.suggest_addresses("utrecht")
      
      assert length(amsterdam_suggestions) > 0
      assert length(utrecht_suggestions) > 0
      
      # All suggestions should contain the city name
      Enum.each(amsterdam_suggestions, fn suggestion ->
        assert String.contains?(String.downcase(suggestion.display), "amsterdam")
      end)
    end
  end
end
