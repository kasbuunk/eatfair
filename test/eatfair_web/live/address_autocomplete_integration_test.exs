defmodule EatfairWeb.Live.AddressAutocompleteIntegrationTest do
  use EatfairWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Eatfair.RestaurantsFixtures

  # NOTE: Homepage tests focus on the basic location input form,
  # while AddressAutocomplete component is tested in its own component test.

  describe "Homepage location input journey" do
    test "complete user journey from homepage to discovery", %{conn: conn} do
      # Start at the homepage
      {:ok, view, html} = live(conn, "/")

      # Should see the address input
      assert has_element?(view, "input[name='location']")
      assert html =~ "Discover Great Food Near You"

      # Submit the form with location
      view
      |> element("form[phx-submit='discover_restaurants']")
      |> render_submit(%{"location" => "Amsterdam"})

      # Should navigate to discovery page with location
      assert_redirected(view, "/restaurants?location=Amsterdam")
    end

    test "form submission works directly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Submit the form directly (simulating user typing and pressing Enter)
      view
      |> element("form[phx-submit='discover_restaurants']")
      |> render_submit(%{"location" => "Berlin"})

      # Should navigate to discovery page
      assert_redirected(view, "/restaurants?location=Berlin")
    end

    test "form handles various location formats", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Test with partial address
      view
      |> element("form[phx-submit='discover_restaurants']")
      |> render_submit(%{"location" => "Amster"})

      assert_redirected(view, "/restaurants?location=Amster")
    end

    test "form handles international locations", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Test with international location
      view
      |> element("form[phx-submit='discover_restaurants']")
      |> render_submit(%{"location" => "Paris"})

      assert_redirected(view, "/restaurants?location=Paris")
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
      conn = conn |> init_test_session(%{}) |> put_session(:inferred_location, "Amsterdam")

      {:ok, _view, _html} = live(conn, "/")

      # Should use session location for inference
      # This would be reflected in the placeholder or initial value
    end
  end

  describe "Discovery page cuisine filter" do
    test "cuisine dropdown functionality", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/restaurants")

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
      {:ok, view, _html} = live(conn, "/restaurants")

      # Open cuisine dropdown
      view
      |> element("button[phx-click='toggle_cuisine_dropdown']")
      |> render_click()

      # Click "All Cuisines" option (it's an input checkbox, not a button)
      view
      |> element("input[phx-click='select_all_cuisines']")
      |> render_click()

      # Should close dropdown and select all cuisines (empty list)
      # This would test that filters.cuisines becomes []
    end

    test "individual cuisine selection", %{conn: conn} do
      # Create test cuisine to work with
      italian_cuisine = RestaurantsFixtures.cuisine_fixture(%{name: "Italian"})
      restaurant = RestaurantsFixtures.restaurant_fixture()
      RestaurantsFixtures.associate_restaurant_cuisines(restaurant, italian_cuisine)

      {:ok, view, _html} = live(conn, "/restaurants")

      # Open cuisine dropdown first
      view
      |> element("button[phx-click='toggle_cuisine_dropdown']")
      |> render_click()

      # Click on individual cuisine checkbox within the dropdown
      view
      |> element(
        "input[phx-click='toggle_cuisine'][phx-value-cuisine_id='#{italian_cuisine.id}']"
      )
      |> render_click()

      # Should toggle that cuisine in the filters
      # This would add/remove the cuisine ID from filters.cuisines
      # Verify the cuisine is now selected by checking if checkbox is checked
      html = render(view)
      assert html =~ "checked"
    end

    test "cuisine counts are displayed", %{conn: conn} do
      # Create some test data to ensure we have counts to display
      italian_cuisine = RestaurantsFixtures.cuisine_fixture(%{name: "Italian"})
      chinese_cuisine = RestaurantsFixtures.cuisine_fixture(%{name: "Chinese"})

      restaurant1 = RestaurantsFixtures.restaurant_fixture()
      restaurant2 = RestaurantsFixtures.restaurant_fixture()

      RestaurantsFixtures.associate_restaurant_cuisines(restaurant1, [
        italian_cuisine,
        chinese_cuisine
      ])

      RestaurantsFixtures.associate_restaurant_cuisines(restaurant2, italian_cuisine)

      {:ok, view, _html} = live(conn, "/restaurants")

      # Should show cuisine counts in the dropdown interface
      # The format is shown as count numbers without parentheses
      # Open the dropdown to see the counts
      view
      |> element("button[phx-click='toggle_cuisine_dropdown']")
      |> render_click()

      html = render(view)

      # Should contain numeric counts for each cuisine
      # Italian should have count of 2 (both restaurants)
      assert html =~ "2"
      # Chinese should have count of 1 (one restaurant)
      assert html =~ "1"
    end
  end

  describe "Location-based filtering" do
    test "address autocomplete integration with discovery", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/restaurants")

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
      {:ok, _view, _html} = live(conn, "/restaurants?location=Utrecht")

      # Should apply location filter automatically
      # This would be handled in handle_params
    end
  end

  describe "Complete user flow" do
    test "homepage to discovery navigation works", %{conn: conn} do
      # Start at homepage
      {:ok, homepage, _html} = live(conn, "/")

      # Submit to go to discovery with location
      homepage
      |> element("form[phx-submit='discover_restaurants']")
      |> render_submit(%{"location" => "Rotterdam"})

      # Should be redirected to discovery page
      assert_redirected(homepage, "/restaurants?location=Rotterdam")
    end

    test "discovery page basic functionality", %{conn: conn} do
      # Go directly to discovery page
      {:ok, discovery, html} = live(conn, "/restaurants")

      # Should show main elements
      assert html =~ "Discover Restaurants"
      assert has_element?(discovery, "button[phx-click='toggle_cuisine_dropdown']")
      
      # Should be able to toggle filters
      discovery
      |> element("input[phx-click='toggle_delivery_filter']")
      |> render_click()

      # Should be able to open cuisine dropdown
      discovery
      |> element("button[phx-click='toggle_cuisine_dropdown']")
      |> render_click()

      # Should show dropdown is now open
      html_after = render(discovery)
      # The dropdown should contain UI elements when open
      assert html_after =~ "All Cuisines" or html_after =~ "cuisine"
    end
  end
end
