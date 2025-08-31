defmodule Eatfair.AddressParserTest do
  use ExUnit.Case

  alias Eatfair.AddressParser

  doctest AddressParser

  describe "parse_delivery_address/1" do
    test "parses Dutch full format correctly" do
      # Standard Dutch format
      assert {"Prinsengracht 263", "Amsterdam", "1016 GV"} =
               AddressParser.parse_delivery_address("Prinsengracht 263, 1016 GV Amsterdam")

      # With lowercase postal code
      assert {"Damrak 1", "Amsterdam", "1012 JS"} =
               AddressParser.parse_delivery_address("Damrak 1, 1012 js Amsterdam")

      # With complex street name
      assert {"Nieuwezijds Voorburgwal 147", "Amsterdam", "1012 RJ"} =
               AddressParser.parse_delivery_address(
                 "Nieuwezijds Voorburgwal 147, 1012 RJ Amsterdam"
               )

      # With apartment/unit numbers
      assert {"Herengracht 123A", "Amsterdam", "1015 BE"} =
               AddressParser.parse_delivery_address("Herengracht 123A, 1015 BE Amsterdam")
    end

    test "parses simple street, city format" do
      # Just street and city - now provides default postal code
      assert {"Damrak 1", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address("Damrak 1, Amsterdam")

      # With extra spaces
      assert {"Main Street 42", "Rotterdam", "1000 AA"} =
               AddressParser.parse_delivery_address("  Main Street 42  ,  Rotterdam  ")
    end

    test "handles complex multi-comma formats" do
      # Dutch format with country
      assert {"Keizersgracht 424", "Amsterdam", "1016 GC"} =
               AddressParser.parse_delivery_address(
                 "Keizersgracht 424, 1016 GC Amsterdam, Netherlands"
               )

      # Street, postal+city, country
      assert {"Vondelstraat 12", "Amsterdam", "1054 GE"} =
               AddressParser.parse_delivery_address("Vondelstraat 12, 1054 GE Amsterdam, NL")

      # With neighborhood/district
      assert {"Rokin 85", "Amsterdam", "1012 KL"} =
               AddressParser.parse_delivery_address("Rokin 85, 1012 KL Amsterdam, Centrum")
    end

    test "handles postal code normalization" do
      # No space in postal code
      assert {"Test Street 1", "Amsterdam", "1000 AB"} =
               AddressParser.parse_delivery_address("Test Street 1, 1000AB Amsterdam")

      # Lowercase letters
      assert {"Test Street 2", "Amsterdam", "1000 CD"} =
               AddressParser.parse_delivery_address("Test Street 2, 1000cd Amsterdam")

      # Mixed case
      assert {"Test Street 3", "Amsterdam", "1000 EF"} =
               AddressParser.parse_delivery_address("Test Street 3, 1000Ef Amsterdam")
    end

    test "handles edge cases and fallbacks" do
      # Single component - fallback
      assert {"Just Street Name", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address("Just Street Name")

      # Empty string
      assert {"", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address("")

      # Only spaces
      assert {"", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address("   ")

      # Nil input
      assert {"", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address(nil)

      # Non-string input
      assert {"", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address(123)
    end

    test "extracts postal code from various positions" do
      # Postal code in the middle
      assert {"Koekoeklaan 31", "Bussum", "1403 EB"} =
               AddressParser.parse_delivery_address("Koekoeklaan 31, 1403 EB Bussum, Netherlands")

      # Postal code at end (less common but should work)
      address_with_postal_at_end = "Street Name, City Name, 1234 AB"
      {street, city, postal} = AddressParser.parse_delivery_address(address_with_postal_at_end)
      assert String.contains?(street <> city, "Street Name")
      assert postal == "1234 AB"
    end

    test "handles international variations gracefully" do
      # UK-style postcode (should fallback gracefully)
      assert {"10 Downing Street", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address("10 Downing Street, London SW1A 2AA, UK")

      # US-style address (should fallback gracefully)  
      assert {"123 Main St", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address("123 Main St, New York, NY 10001")
    end
  end

  describe "valid_address?/1" do
    test "validates complete addresses" do
      assert AddressParser.valid_address?({"Street 1", "City", "1000 AA"}) == true

      assert AddressParser.valid_address?({"Long Street Name 123", "Amsterdam", "1016 GV"}) ==
               true
    end

    test "rejects incomplete addresses" do
      assert AddressParser.valid_address?({"", "City", "1000 AA"}) == false
      assert AddressParser.valid_address?({"Street", "", "1000 AA"}) == false
      assert AddressParser.valid_address?({"Street", "City", ""}) == false
      assert AddressParser.valid_address?({"", "", ""}) == false
    end

    test "rejects addresses with only spaces" do
      assert AddressParser.valid_address?({"   ", "City", "1000 AA"}) == false
      assert AddressParser.valid_address?({"Street", "   ", "1000 AA"}) == false
      assert AddressParser.valid_address?({"Street", "City", "   "}) == false
    end

    test "rejects malformed input" do
      assert AddressParser.valid_address?(nil) == false
      assert AddressParser.valid_address?({}) == false
      assert AddressParser.valid_address?({"only", "two"}) == false
      assert AddressParser.valid_address?({"too", "many", "parts", "here"}) == false
    end
  end

  describe "format_address/1" do
    test "formats complete addresses correctly" do
      assert "Prinsengracht 263, 1016 GV Amsterdam" =
               AddressParser.format_address({"Prinsengracht 263", "Amsterdam", "1016 GV"})

      assert "Main Street 42, 1000 AB City" =
               AddressParser.format_address({"Main Street 42", "City", "1000 AB"})
    end

    test "handles missing postal code" do
      assert "Street Name, Amsterdam" =
               AddressParser.format_address({"Street Name", "Amsterdam", ""})
    end

    test "handles missing city" do
      assert "Street Name" =
               AddressParser.format_address({"Street Name", "", "1000 AB"})
    end

    test "handles empty components" do
      assert "" = AddressParser.format_address({"", "", ""})
      assert "" = AddressParser.format_address(nil)
      assert "" = AddressParser.format_address({})
    end
  end

  describe "real-world address examples" do
    test "handles addresses from actual order data" do
      # These are examples from the feedback description - now provides default postal code
      assert {"Test Address 123", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address("Test Address 123, Amsterdam")

      assert {"Koekoeklaan 31", "Bussum", "1403 EB"} =
               AddressParser.parse_delivery_address("Koekoeklaan 31, 1403 EB Bussum, Netherlands")

      # Address that might come from Google autocomplete
      assert {"Nieuwmarkt 10", "Amsterdam", "1012 CR"} =
               AddressParser.parse_delivery_address(
                 "Nieuwmarkt 10, 1012 CR Amsterdam, Netherlands"
               )
    end

    test "handles messy user input" do
      # Extra commas and spaces
      assert {"Messy Street 1", "Amsterdam", "1000 AA"} =
               AddressParser.parse_delivery_address("Messy Street 1,, Amsterdam,, Netherlands")

      # Mixed formatting  
      assert {"Inconsistent 42", "Rotterdam", "3011 AD"} =
               AddressParser.parse_delivery_address("Inconsistent 42,3011AD Rotterdam")
    end
  end

  describe "property-based patterns" do
    test "parsing and formatting roundtrip preserves structure" do
      test_cases = [
        "Prinsengracht 263, 1016 GV Amsterdam",
        "Simple Street, Rotterdam",
        "Complex Address 123, 1234 AB City, Country"
      ]

      for original_address <- test_cases do
        {street, city, postal} = AddressParser.parse_delivery_address(original_address)

        # Verify components are extracted
        assert String.trim(street) != ""
        assert String.trim(city) != ""

        # If we had a postal code, verify it's in Dutch format
        if postal != "" do
          assert Regex.match?(~r/^\d{4} [A-Z]{2}$/, postal)
        end
      end
    end

    test "all valid Dutch postal codes are properly normalized" do
      postal_variations = [
        "1016GV",
        "1016gv",
        "1016Gv",
        "1016 GV",
        "1016  GV"
      ]

      for postal <- postal_variations do
        address = "Test Street 1, #{postal} Amsterdam"
        {_street, _city, normalized_postal} = AddressParser.parse_delivery_address(address)
        assert normalized_postal == "1016 GV"
      end
    end
  end
end
