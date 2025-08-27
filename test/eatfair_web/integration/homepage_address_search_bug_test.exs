defmodule EatfairWeb.Integration.HomepageAddressSearchBugTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures

  @moduledoc """
  Test suite to reproduce and verify the fix for the homepage address search issue
  reported in user feedback:

  1. Flickering "Something went wrong" popups when typing in address field
  2. Incorrect navigation to /restaurants with location=Amsterdam instead of typed address
  3. Need for Google Maps-like autocomplete experience

  This test simulates the actual user behavior pattern to ensure the bug is fixed.
  """

  describe "Homepage Address Search - Bug Reproduction & Fix Verification" do
    test "user can type addresses without triggering visible error messages", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/")

      # Simulate user typing and check for visible errors
      test_addresses = ["Damrak 1", "Utrecht", "Rotterdam"]

      for address <- test_addresses do
        # The component should handle input changes without LiveView errors
        # We test by sending messages that would be sent by the AddressAutocomplete component
        send(lv.pid, {"input_change", address})

        # Render to process any queued messages
        render(lv)

        # The key test - errors should be hidden (not visible to users)
        # Phoenix LiveView includes error templates but they should be hidden="" in normal operation
        refute has_element?(lv, "#client-error:not([hidden])")
        refute has_element?(lv, "#server-error:not([hidden])")
        refute has_element?(lv, "[role='alert']:not([hidden])")
        refute has_element?(lv, ".phx-flash-error:not([hidden])")
      end
    end

    test "form submission preserves typed addresses instead of defaulting to Amsterdam", %{
      conn: conn
    } do
      # Test addresses that should be preserved, not replaced with Amsterdam
      test_cases = [
        # Phoenix uses + encoding for spaces
        {"Utrecht Centraal", "Utrecht+Centraal"},
        {"Rotterdam", "Rotterdam"},
        {"Nieuwmarkt 1", "Nieuwmarkt+1"}
      ]

      for {typed_address, expected_encoded} <- test_cases do
        # Fresh page load for each test case
        {:ok, lv, _html} = live(conn, "/")

        # Simulate the address autocomplete component updating the form
        send(lv.pid, {"input_change", typed_address})

        # Submit form with the typed address
        lv
        |> form("#discover-form", %{"location" => typed_address})
        |> render_submit()

        # Should redirect to restaurants page with actual typed address, NOT Amsterdam
        expected_path = "/restaurants?location=#{expected_encoded}"
        assert_redirected(lv, expected_path)
      end
    end

    test "address autocomplete system provides good suggestions", %{conn: conn} do
      # Test that the AddressAutocomplete module provides good suggestions
      alias Eatfair.AddressAutocomplete

      # Test fuzzy/semantic search behavior directly
      search_cases = [
        # Should find Dam-related addresses
        {"dam", ["Dam", "Damrak"]},

        # Should find Prinsengracht addresses  
        {"prinsen", ["Prinsengracht"]},

        # Postal code search should work
        {"1012", ["1012"]},

        # Should handle partial street names
        {"heren", ["Herengracht"]}
      ]

      for {query, expected_suggestions} <- search_cases do
        suggestions = AddressAutocomplete.suggest_addresses(query)

        # Should return suggestions for valid queries
        assert length(suggestions) > 0

        # Should contain expected suggestions
        suggestion_texts = Enum.map(suggestions, & &1.display)

        for expected <- expected_suggestions do
          assert Enum.any?(suggestion_texts, &String.contains?(&1, expected))
        end
      end
    end

    test "complete address selection journey works without errors", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/")

      # Simulate user selecting an address via component message
      selected_address = "Dam 1, 1012AB Amsterdam"
      send(lv.pid, {"location_selected", selected_address})

      # Submit form with selected address
      lv
      |> form("#discover-form", %{"location" => selected_address})
      |> render_submit()

      # Check that we get redirected to restaurants (pattern match assertion doesn't work in tests)
      expected_path = "/restaurants?location=Dam+1%2C+1012AB+Amsterdam"
      assert_redirected(lv, expected_path)
    end

    test "address autocomplete handles edge cases gracefully", %{conn: conn} do
      alias Eatfair.AddressAutocomplete

      # Empty input should not cause errors and return no suggestions
      suggestions = AddressAutocomplete.suggest_addresses("")
      assert suggestions == []

      # Single character should return no suggestions
      suggestions = AddressAutocomplete.suggest_addresses("a")
      assert suggestions == []

      # Very short input should not crash
      suggestions = AddressAutocomplete.suggest_addresses("x")
      assert is_list(suggestions)

      # Invalid characters should not crash
      suggestions = AddressAutocomplete.suggest_addresses("@#$%")
      assert is_list(suggestions)
    end

    test "form submission with empty address uses smart fallback without errors", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/")

      # Submit form with empty address
      lv
      |> form("#discover-form", %{"location" => ""})
      |> render_submit()

      # Should handle gracefully and redirect with Amsterdam as fallback
      assert_redirected(lv, "/restaurants?location=Amsterdam")
    end

    test "form preserves user's typed address value on submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/")

      # User types a specific address
      user_input = "Nieuwmarkt 1"

      # Simulate the input change via message (like AddressAutocomplete would send)
      send(lv.pid, {"input_change", user_input})

      # Form submission should use the user's typed value
      lv
      |> form("#discover-form", %{"location" => user_input})
      |> render_submit()

      # Should redirect with the typed address (with proper encoding)
      assert_redirected(lv, "/restaurants?location=Nieuwmarkt+1")
    end
  end
end
