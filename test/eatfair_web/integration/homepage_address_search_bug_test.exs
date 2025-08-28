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

    test "homepage simple form handles input correctly", %{conn: conn} do
      # The homepage uses a simple form, not the AddressAutocomplete component
      # This test verifies the simple form works correctly

      # Test basic form submission with different addresses
      test_addresses = ["Utrecht", "Rotterdam", "Amsterdam"]

      for address <- test_addresses do
        # Get a fresh view for each test
        {:ok, lv, _html} = live(conn, "/")

        # Find the simple address input on homepage
        assert has_element?(lv, "input[name='location']")

        # Submit the form with the address
        lv
        |> element("form[phx-submit='discover_restaurants']")
        |> render_submit(%{"location" => address})

        # Should redirect to discovery page
        assert_redirected(lv, "/restaurants?location=#{address}")
      end
    end

    @tag :focus
    test "CRITICAL BUG: typing regular characters should NOT crash AddressAutocomplete component",
         %{conn: conn} do
      # This test reproduces the exact FunctionClauseError crash described in logs:
      # ** (FunctionClauseError) no function clause matching in 
      # EatfairWeb.Live.Components.AddressAutocomplete.handle_event/3
      # When users type regular characters like "h", "a", etc.

      {:ok, lv, _html} = live(conn, "/")

      # Find the address input - it should have the AddressAutocomplete component
      assert has_element?(lv, "input[placeholder*='Amsterdam']")

      # These keystrokes currently cause FunctionClauseError crashes:
      crash_causing_keys = [
        # Regular typing
        %{"key" => "h", "value" => ""},
        # Continued typing
        %{"key" => "a", "value" => "h"},
        # Modifier keys  
        %{"key" => "Meta", "value" => "ha"},
        # More typing
        %{"key" => "m", "value" => "ham"}
      ]

      # Each of these should work WITHOUT crashing the LiveView
      for key_event <- crash_causing_keys do
        # This previously crashed with FunctionClauseError because 
        # AddressAutocomplete.handle_event("keyboard_navigation", key_event, socket)
        # had no catch-all clause for regular typing keys

        # After fix, this should NOT raise any FunctionClauseError
        # The main test is that render_keydown completes successfully
        result =
          lv
          |> element("input[placeholder*='Amsterdam']")
          |> render_keydown(key_event)

        # The key assertion: no crash occurred (render_keydown returned successfully)
        assert is_binary(result), "Keydown event should complete without crashing"

        # Verify LiveView is still functional after the keypress
        html = render(lv)
        assert html =~ "Discover Great Food", "Homepage should still be rendered after keypress"
      end

      # Navigation keys should continue to work properly
      navigation_keys = [
        %{"key" => "ArrowDown"},
        %{"key" => "ArrowUp"},
        %{"key" => "Enter"},
        %{"key" => "Tab"},
        %{"key" => "Escape"}
      ]

      for key_event <- navigation_keys do
        # These should work without crashing (they already do)
        lv
        |> element("input[placeholder*='Amsterdam']")
        |> render_keydown(key_event)

        # Verify no crash
        html = render(lv)
        assert html =~ "Discover Great Food"
      end
    end

    test "comprehensive keyboard input validation - all keys should work without crashes", %{
      conn: conn
    } do
      # This comprehensive test validates the fix by testing a wide range of keyboard inputs
      {:ok, lv, _html} = live(conn, "/")

      # Test all regular typing characters that users might enter
      typing_keys = [
        # Letters
        "a",
        "b",
        "c",
        "h",
        "m",
        "n",
        "z",
        "A",
        "B",
        "Z",
        # Numbers 
        "0",
        "1",
        "2",
        "9",
        # Special characters common in addresses
        " ",
        "-",
        ".",
        ",",
        "/",
        "(",
        ")",
        # International characters
        "ü",
        "ä",
        "ö",
        "ß",
        "ñ",
        "é",
        "ç"
      ]

      # Test modifier key combinations
      modifier_combinations = [
        %{"key" => "Meta", "value" => "a"},
        %{"key" => "Ctrl", "value" => "c"},
        %{"key" => "Alt", "value" => "tab"},
        %{"key" => "Shift", "value" => "A"},
        %{"key" => "CapsLock", "value" => "test"},
        %{"key" => "Meta", "value" => "Backspace"}
      ]

      # Test all regular typing - should not crash
      for key <- typing_keys do
        result =
          lv
          |> element("input[placeholder*='Amsterdam']")
          |> render_keydown(%{"key" => key, "value" => "current_#{key}"})

        assert is_binary(result), "Regular key '#{key}' should not crash component"
      end

      # Test all modifier combinations - should not crash
      for key_combo <- modifier_combinations do
        result =
          lv
          |> element("input[placeholder*='Amsterdam']")
          |> render_keydown(key_combo)

        assert is_binary(result),
               "Modifier combo #{inspect(key_combo)} should not crash component"
      end

      # Verify LiveView is still functional after all keystrokes
      html = render(lv)

      assert html =~ "Discover Great Food",
             "Homepage should remain functional after comprehensive keyboard test"
    end
  end
end
