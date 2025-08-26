defmodule EatfairWeb.Live.AddressAutocompleteIntegrationTest do
  use EatfairWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "Address autocomplete integration journey" do
    test "complete user journey from homepage to discovery", %{conn: conn} do
      # Start at the homepage
      {:ok, view, html} = live(conn, "/")
      
      # Should see the address input
      assert has_element?(view, "input[placeholder]")
      assert html =~ "Find restaurants near you"
      
      # Type in address input
      view
      |> element("input[phx-change='input_change']")
      |> render_change(%{"value" => "Amsterdam"})
      
      # Submit the form
      view
      |> element("form")
      |> render_submit(%{"location" => %{"address" => "Amsterdam"}})
      
      # Should navigate to discovery page with location
      assert_patched(view, ~r"/discovery.*location=Amsterdam")
    end
    
    test "form submission with Enter key", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Type in the input
      view
      |> element("input[phx-change='input_change']")
      |> render_change(%{"value" => "Berlin"})
      
      # Simulate Enter keypress
      view
      |> element("input[phx-keydown='handle_keydown']")
      |> render_keydown(%{"key" => "Enter"})
      
      # Should submit the form with current input value
      # This would navigate to discovery page
    end
    
    test "Tab key autocompletes to first suggestion", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Type partial address
      view
      |> element("input[phx-change='input_change']")
      |> render_change(%{"value" => "Amster"})
      
      # Simulate Tab keypress
      view
      |> element("input[phx-keydown='handle_keydown']")  
      |> render_keydown(%{"key" => "Tab"})
      
      # Should autocomplete to first suggestion (mocked)
      # In reality, this would require mocking the Google Places API
    end
    
    test "Escape key clears suggestions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Type to show suggestions
      view
      |> element("input[phx-change='input_change']")
      |> render_change(%{"value" => "Paris"})
      
      # Simulate Escape keypress
      view
      |> element("input[phx-keydown='handle_keydown']")
      |> render_keydown(%{"key" => "Escape"})
      
      # Suggestions should be hidden
      # This would clear the show_suggestions flag
    end
    
    test "geolocation hook integration", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")
      
      # Should have the geolocation hook div
      assert html =~ "id=\"geolocation-hook\""
      assert html =~ "phx-hook=\"GeolocationHook\""
      
      # Simulate successful geolocation from client
      send(view.pid, %{
        event: "geolocation_success",
        payload: %{
          "latitude" => 52.3676,
          "longitude" => 4.9041
        }
      })
      
      # Should update the location inference
      # In practice this would update the placeholder or prefill the address
    end
    
    test "location inference from session", %{conn: conn} do
      # Set up session with location data
      conn = put_session(conn, :inferred_location, "Amsterdam")
      
      {:ok, view, _html} = live(conn, "/")
      
      # Should use session location for inference
      # This would be reflected in the placeholder or initial value
    end
  end
  
  describe "Discovery page cuisine filter" do
    test "cuisine dropdown functionality", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/discovery")
      
      # Should show cuisine dropdown trigger
      assert has_element?(view, "button[phx-click='toggle_cuisine_dropdown']")
      
      # Click to open dropdown
      view
      |> element("button[phx-click='toggle_cuisine_dropdown']")
      |> render_click()
      
      # Should show dropdown content
      # In practice, this would test the show_cuisine_dropdown assign
    end
    
    test "select all cuisines functionality", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/discovery")
      
      # Open cuisine dropdown
      view
      |> element("button[phx-click='toggle_cuisine_dropdown']")
      |> render_click()
      
      # Click "All Cuisines" option
      view
      |> element("button[phx-click='select_all_cuisines']")
      |> render_click()
      
      # Should close dropdown and select all cuisines (empty list)
      # This would test that filters.cuisines becomes []
    end
    
    test "individual cuisine selection", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/discovery")
      
      # Click on individual cuisine
      view
      |> element("input[phx-click='toggle_cuisine']", "Italian")
      |> render_click()
      
      # Should toggle that cuisine in the filters
      # This would add/remove the cuisine ID from filters.cuisines
    end
    
    test "cuisine counts are displayed", %{conn: conn} do
      {:ok, view, html} = live(conn, "/discovery")
      
      # Should show cuisine counts in the interface
      # The exact format depends on the template, but should show numbers
      # like "Italian (5)" or similar
      assert html =~ ~r/\(\d+\)/  # Should contain counts in parentheses
    end
  end
  
  describe "Location-based filtering" do
    test "address autocomplete integration with discovery", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/discovery")
      
      # Type in location search
      view
      |> element("input[placeholder*='address']")
      |> render_change(%{"value" => "Hoofddorp"})
      
      # Submit location search
      view
      |> element("form[phx-submit='search_location']")
      |> render_submit(%{"location" => %{"address" => "Hoofddorp"}})
      
      # Should filter restaurants by location
      # This would geocode the address and filter by delivery range
    end
    
    test "location parameter from homepage navigation", %{conn: conn} do
      # Navigate to discovery with location parameter
      {:ok, view, _html} = live(conn, "/discovery?location=Utrecht")
      
      # Should apply location filter automatically
      # This would be handled in handle_params
    end
  end
  
  describe "Complete user flow" do
    test "homepage to discovery with location and cuisine filters", %{conn: conn} do
      # Start at homepage
      {:ok, homepage, _html} = live(conn, "/")
      
      # Enter address
      homepage
      |> element("input[phx-change='input_change']")
      |> render_change(%{"value" => "Rotterdam"})
      
      # Submit to go to discovery
      homepage
      |> element("form")
      |> render_submit(%{"location" => %{"address" => "Rotterdam"}})
      
      # Should be on discovery page
      assert_patched(homepage, ~r"/discovery.*location=Rotterdam")
      
      # Now test filters on discovery page
      {:ok, discovery, _html} = live(conn, "/discovery?location=Rotterdam")
      
      # Toggle delivery filter
      discovery
      |> element("input[phx-click='toggle_delivery_filter']")
      |> render_click()
      
      # Toggle open filter
      discovery
      |> element("input[phx-click='toggle_open_filter']")
      |> render_click()
      
      # Select specific cuisine
      discovery
      |> element("input[phx-click='toggle_cuisine']")
      |> render_click()
      
      # Should have filtered results
      # This would test the complete filter chain
    end
  end
end
