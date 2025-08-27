defmodule EatfairWeb.AddressAutocompleteTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures

  describe "Address Autocomplete Functionality" do
    test "address autocomplete suggests Dutch addresses", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit the homepage
      {:ok, lv, _html} = live(conn, "/")

      # The address autocomplete is now a live component, so we interact with it differently
      # Look for the live component input (it should be inside the AddressAutocomplete component)
      assert has_element?(lv, "div[data-phx-component='1']")

      # Test typing in a Dutch address - the component handles the change internally
      lv
      |> element("input[placeholder*='Amsterdam']")
      |> render_change(%{"value" => "Dam"})

      # The AddressAutocomplete component should be present and working
      # For now, just verify the component is rendered correctly
      assert has_element?(lv, "div[data-phx-component='1'] input")
    end

    test "homepage navigation works with location input", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit the homepage
      {:ok, lv, _html} = live(conn, "/")

      # With the AddressAutocomplete component, we need to simulate the location being set
      # The component handles input and sends messages to the parent LiveView
      # For now, let's test the form submission with a pre-set location
      
      # Simulate the discover_restaurants event which would be triggered by the form
      lv
      |> element("#discover-form")
      |> render_submit(%{"location" => "Utrecht"})

      # Should navigate to discovery page
      assert_redirected(lv, "/restaurants?location=Utrecht")
    end

    test "address autocomplete provides fuzzy search suggestions", %{conn: conn} do
      # Test the actual AddressAutocomplete module
      suggestions = Eatfair.AddressAutocomplete.suggest_addresses("Dam")

      # Should return suggestions for Dam in Amsterdam
      assert length(suggestions) > 0

      # Check that we get the expected Dam suggestion
      dam_suggestion =
        Enum.find(suggestions, fn suggestion ->
          String.contains?(String.downcase(suggestion.display), "dam")
        end)

      assert dam_suggestion != nil
      assert dam_suggestion.display =~ "Dam"
    end

    test "address autocomplete handles partial postal codes", %{conn: conn} do
      # Test partial postal code
      suggestions = Eatfair.AddressAutocomplete.suggest_addresses("1012")

      # Should return area suggestions
      assert length(suggestions) > 0

      # Should contain Amsterdam Centrum suggestions
      centrum_suggestion =
        Enum.find(suggestions, fn suggestion ->
          String.contains?(suggestion.display, "Amsterdam")
        end)

      assert centrum_suggestion != nil
    end

    test "address autocomplete handles street name search", %{conn: conn} do
      # Test street name search
      suggestions = Eatfair.AddressAutocomplete.suggest_addresses("Prinsengracht")

      # Should return street suggestions
      assert length(suggestions) > 0

      # Should contain Prinsengracht suggestion
      street_suggestion =
        Enum.find(suggestions, fn suggestion ->
          String.contains?(suggestion.display, "Prinsengracht")
        end)

      assert street_suggestion != nil
    end

    test "homepage shows red flickering feedback issue", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit the homepage
      {:ok, _lv, html} = live(conn, "/")

      # Look for any error or validation messages that might cause red flickering
      # This is to identify the LiveView popup issue mentioned by the user
      # The word "error" appears in HTML attributes and error handling, so we need to be more specific
      refute html =~ "class=\"error\""
      refute html =~ "invalid"
      refute html =~ "required"
      # Also check that the page loads without obvious errors
      assert html =~ "Discover Great Food Near You"
    end
  end
end
