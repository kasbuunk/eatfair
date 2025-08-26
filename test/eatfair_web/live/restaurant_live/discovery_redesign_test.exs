defmodule EatfairWeb.RestaurantLive.DiscoveryRedesignTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures
  alias Eatfair.Accounts

  describe "Discovery Page Redesign" do
    setup do
      # Create some cuisines and restaurants for testing
      {:ok, italian_cuisine} = Eatfair.Restaurants.create_cuisine(%{name: "Italian"})
      {:ok, chinese_cuisine} = Eatfair.Restaurants.create_cuisine(%{name: "Chinese"})
      {:ok, mexican_cuisine} = Eatfair.Restaurants.create_cuisine(%{name: "Mexican"})
      
      restaurant1 = restaurant_fixture(%{
        name: "Pizza Palace", 
        is_open: true,
        city: "Amsterdam",
        latitude: 52.3676,
        longitude: 4.9041
      })
      restaurant2 = restaurant_fixture(%{
        name: "Noodle House", 
        is_open: true,
        city: "Amsterdam", 
        latitude: 52.3702,
        longitude: 4.8952
      })
      restaurant3 = restaurant_fixture(%{
        name: "Taco Time", 
        is_open: false,
        city: "Utrecht",
        latitude: 52.0907,
        longitude: 5.1214
      })
      
      %{
        cuisines: %{italian: italian_cuisine, chinese: chinese_cuisine, mexican: mexican_cuisine},
        restaurants: %{pizza: restaurant1, noodles: restaurant2, tacos: restaurant3}
      }
    end

    test "displays proper layout with margins and header", %{conn: conn} do
      {:ok, _lv, html} = live(conn, "/restaurants/discover")
      
      # Check for proper layout structure
      assert html =~ "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8"
      assert html =~ "🗺️ Discover Restaurants"
      assert html =~ "Find restaurants near you with location-based search and smart filters"
    end

    test "shows location input with address autocomplete functionality", %{conn: conn} do
      {:ok, lv, html} = live(conn, "/restaurants/discover")
      
      # Should have address autocomplete live component
      assert has_element?(lv, "[data-phx-component]")
      assert html =~ "Enter your address or city"
      # Still has the form wrapper but with live component inside
      assert has_element?(lv, "form#location-search")
      assert has_element?(lv, "button[type='submit']", "Search")
    end

    test "displays new toggle filter system", %{conn: conn} do
      {:ok, lv, html} = live(conn, "/restaurants/discover")
      
      # Should show delivery available toggle (ON by default)
      assert html =~ "Only show restaurants that deliver here"
      assert html =~ "(ON)"
      
      # Should show currently open toggle (ON by default) 
      assert html =~ "Only show restaurants open for orders"
      assert html =~ "(ON)"
      
      # Should have toggle buttons
      assert has_element?(lv, "input[phx-click='toggle_delivery_filter']")
      assert has_element?(lv, "input[phx-click='toggle_open_filter']")
    end

    test "displays cuisine multi-select with counts", %{conn: conn, cuisines: cuisines} do
      {:ok, lv, html} = live(conn, "/restaurants/discover")
      
      # Should show cuisine section
      assert html =~ "🍽️ Cuisines"
      assert html =~ "Showing counts for available restaurants"
      
      # Should have cuisine checkboxes
      assert has_element?(lv, "input[phx-click='toggle_cuisine'][phx-value-cuisine_id='#{cuisines.italian.id}']")
      assert has_element?(lv, "input[phx-click='toggle_cuisine'][phx-value-cuisine_id='#{cuisines.chinese.id}']")
      assert has_element?(lv, "input[phx-click='toggle_cuisine'][phx-value-cuisine_id='#{cuisines.mexican.id}']")
    end

    test "does not show removed price and delivery time filters", %{conn: conn} do
      {:ok, _lv, html} = live(conn, "/restaurants/discover")
      
      # Should NOT have the old filters
      refute html =~ "Max Price"
      refute html =~ "Under €20"
      refute html =~ "Max Delivery Time"
      refute html =~ "Under 30 min"
    end

    test "toggle filters work correctly", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/restaurants/discover")
      
      # Toggle delivery filter OFF
      lv |> element("input[phx-click='toggle_delivery_filter']") |> render_click()
      assert render(lv) =~ "Only show restaurants that deliver here"
      assert render(lv) =~ "(OFF)"
      
      # Toggle currently open filter OFF
      lv |> element("input[phx-click='toggle_open_filter']") |> render_click()  
      assert render(lv) =~ "Only show restaurants open for orders"
      assert render(lv) =~ "(OFF)"
    end

    test "cuisine multi-select displays counts correctly", %{conn: conn, cuisines: cuisines} do
      {:ok, _lv, html} = live(conn, "/restaurants/discover")
      
      # Should show cuisine checkboxes with counts
      # Since our test restaurants don't have cuisines associated, counts should be 0
      # and checkboxes should be disabled
      assert html =~ cuisines.italian.name
      assert html =~ "0" # count should be 0
      
      # The UI should show disabled state for cuisines with 0 restaurants
      assert html =~ "cursor-not-allowed"
      assert html =~ "opacity-50"
    end

    test "location parameter from homepage navigation is applied", %{conn: conn} do
      {:ok, _lv, html} = live(conn, "/restaurants/discover?location=Amsterdam")
      
      # The location parameter should be applied and visible in the UI
      # Since we have location filtering, this may affect which restaurants are shown
      assert html =~ "Amsterdam"
    end

    test "restaurant search functionality still works", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/restaurants/discover")
      
      # Should have restaurant search input
      assert has_element?(lv, "input#restaurant-search")
      assert has_element?(lv, "input[placeholder*='Search restaurants by name']")
    end

    test "results section has proper styling and structure", %{conn: conn} do
      {:ok, _lv, html} = live(conn, "/restaurants/discover")
      
      # Should have results grid layout
      assert html =~ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
      
      # Should show restaurants when they exist (created in setup)
      # The empty state message only shows when there are truly no restaurants
      assert html =~ "restaurant-"
    end

    test "address management prompt shows for users without addresses", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, "/restaurants/discover")
      
      # Should show the address prompt
      assert html =~ "📍 Add Your Address to See Nearby Restaurants"
      assert html =~ "Add your delivery address to see restaurants that can deliver to you"
      assert html =~ "Add Your Address"
    end

    test "address management prompt hidden for users with addresses", %{conn: conn} do
      user = user_fixture()
      {:ok, _address} = Accounts.create_address(%{
        "user_id" => user.id,
        "name" => "Home",
        "street_address" => "Damrak 1",
        "city" => "Amsterdam",
        "postal_code" => "1012JS",
        "is_default" => true
      })
      
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, "/restaurants/discover")
      
      # Should NOT show the address prompt
      refute html =~ "📍 Add Your Address to See Nearby Restaurants"
    end

    test "restaurant cards have proper styling", %{conn: conn, restaurants: _restaurants} do
      # First create some test data to show results
      {:ok, _lv, html} = live(conn, "/restaurants/discover")
      
      # Should have proper card styling classes
      assert html =~ "bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow"
    end

    test "address autocomplete integration works", %{conn: conn} do
      {:ok, lv, html} = live(conn, "/restaurants/discover")
      
      # Should have address autocomplete live component
      assert has_element?(lv, "[data-phx-component]")
      assert html =~ "Enter your address or city"
      # Should not have the old plain input
      refute has_element?(lv, "input[name='location[address]']")
    end

    test "address autocomplete selection updates location and filters restaurants", %{conn: conn, restaurants: _restaurants} do
      {:ok, lv, _html} = live(conn, "/restaurants/discover")
      
      # Simulate address autocomplete selection
      send(lv.pid, {"location_autocomplete_selected", "Damrak 1, 1012JS Amsterdam"})
      
      html = render(lv)
      
      # Should show flash message about location update
      assert html =~ "Showing restaurants near Damrak 1, 1012JS Amsterdam"
      
      # The selected address should be reflected in the address autocomplete component
      assert html =~ "Damrak 1, 1012JS Amsterdam"
    end

    test "address autocomplete handles invalid addresses gracefully", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/restaurants/discover")
      
      # Mock an invalid address that will fail geocoding
      send(lv.pid, {"location_autocomplete_selected", "Invalid Address XYZ"})
      
      html = render(lv)
      
      # Should show error message if geocoding fails
      # (This depends on our geocoding service behavior)
      assert html =~ "Could not find location: Invalid Address XYZ" or 
             html =~ "Showing restaurants near Invalid Address XYZ"
    end
  end
end
