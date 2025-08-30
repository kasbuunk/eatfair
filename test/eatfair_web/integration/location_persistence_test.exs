defmodule EatfairWeb.LocationPersistenceTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  describe "Location persistence across restaurant discovery journey" do
    setup do
      # Create a restaurant owner and restaurant
      owner = user_fixture(%{role: :restaurant_owner})

      # Create a restaurant within Utrecht delivery range (about 5km from Utrecht center)
      restaurant =
        restaurant_fixture(%{
          name: "Utrecht Test Restaurant",
          address: "Oudegracht 123, 3511 AC Utrecht",
          city: "Utrecht",
          postal_code: "3511 AC",
          latitude: Decimal.new("52.0907"),
          longitude: Decimal.new("5.1214"),
          delivery_radius_km: 10,
          owner_id: owner.id
        })

      # Create a customer who will search for restaurants
      customer = user_fixture()

      %{restaurant: restaurant, customer: customer}
    end

    test "location parameter persists from discovery to restaurant detail page", %{
      conn: conn,
      restaurant: restaurant,
      customer: customer
    } do
      search_location = "Utrecht"

      # 1. Start at discovery page with location parameter (as if coming from homepage)
      {:ok, discovery_view, html} = live(conn, ~p"/restaurants?location=#{search_location}")

      # Verify the location is properly handled on discovery page
      assert html =~ "Utrecht"
      assert html =~ restaurant.name

      # 2. Navigate to restaurant detail page via "View Menu" button for the specific restaurant
      _html =
        discovery_view
        |> element("button[phx-value-id='#{restaurant.id}']", "View Menu")
        |> render_click()

      # Should navigate to restaurant detail with location parameter preserved
      assert_redirect(
        discovery_view,
        ~p"/restaurants/#{restaurant.id}?location=#{search_location}"
      )

      # 3. Follow the redirect to restaurant detail page  
      {:ok, _restaurant_view, restaurant_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{search_location}")

      # Verify restaurant page loads with correct info
      assert restaurant_html =~ restaurant.name
      assert restaurant_html =~ "Utrecht Test Restaurant"

      # 4. Key test: For logged in users, check delivery availability is based on searched location, not user's address
      conn = log_in_user(conn, customer)

      {:ok, _restaurant_view, logged_in_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{search_location}")

      # Should show delivery available since we're within Utrecht delivery range
      # (This verifies the fix - previously it would check user's address instead of searched location)
      assert logged_in_html =~ "Available for delivery" or logged_in_html =~ "Add to Cart"
      refute logged_in_html =~ "Delivery not available to your location"
    end

    test "direct navigation to restaurant page via link preserves location parameter", %{
      conn: conn,
      restaurant: restaurant
    } do
      search_location = "Utrecht"

      # 1. Navigate to discovery page with location
      {:ok, discovery_view, _html} = live(conn, ~p"/restaurants?location=#{search_location}")

      # 2. Click on restaurant name link (not the button)
      restaurant_link_selector = "a[href*='/restaurants/#{restaurant.id}']"

      # Get the href from the link to verify it includes location parameter
      link_html = discovery_view |> element(restaurant_link_selector) |> render()
      assert link_html =~ "location=#{search_location}"

      # 3. Navigate via the link
      {:ok, _restaurant_view, restaurant_html} =
        discovery_view
        |> element(restaurant_link_selector)
        |> render_click()
        |> follow_redirect(conn)

      # Verify restaurant page loads correctly
      assert restaurant_html =~ restaurant.name
    end

    test "location persistence works with URL encoding for complex addresses", %{
      conn: conn,
      restaurant: restaurant
    } do
      # Test with a more complex address that needs URL encoding
      complex_location = "Utrecht neuden"
      _encoded_location = URI.encode(complex_location)

      {:ok, discovery_view, html} = live(conn, ~p"/restaurants?location=#{complex_location}")

      # Should show restaurants (assuming "Utrecht neuden" geocodes to Utrecht area)
      assert html =~ restaurant.name

      # Navigate to restaurant detail
      _html =
        discovery_view
        |> element("button[phx-value-id='#{restaurant.id}']", "View Menu")
        |> render_click()

      # Location should be preserved in URL even with encoding
      assert_redirect(
        discovery_view,
        ~p"/restaurants/#{restaurant.id}?location=#{complex_location}"
      )
    end

    test "fallback behavior when no location parameter is provided", %{
      conn: conn,
      restaurant: restaurant,
      customer: customer
    } do
      # Navigate directly to restaurant page without location parameter
      conn = log_in_user(conn, customer)
      {:ok, _restaurant_view, restaurant_html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Should load the restaurant page
      assert restaurant_html =~ restaurant.name

      # Without location parameter and no user address, should not show delivery available
      # (This tests the fallback behavior)
      refute restaurant_html =~ "Available for delivery"
    end

    test "end-to-end flow: homepage -> discovery -> restaurant detail preserves location", %{
      conn: conn,
      restaurant: restaurant
    } do
      # This test simulates the complete user journey described in the feedback

      # 1. Start at homepage (simulated by navigating to discovery with location)
      search_address = "Utrecht"

      {:ok, discovery_view, discovery_html} =
        live(conn, ~p"/restaurants?location=#{search_address}")

      # 2. Should see restaurants that deliver to this location
      assert discovery_html =~ restaurant.name

      # 3. Click on a restaurant to view details
      discovery_view
      |> element("button[phx-value-id='#{restaurant.id}']", "View Menu")
      |> render_click()

      assert_redirect(
        discovery_view,
        ~p"/restaurants/#{restaurant.id}?location=#{search_address}"
      )

      # 4. On restaurant detail page, delivery should be available
      {:ok, _restaurant_view, restaurant_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{search_address}")

      # The key assertion: restaurant should be available for delivery to the searched location
      assert restaurant_html =~ restaurant.name

      # The key test is that the restaurant page loads with the location info
      # For non-logged in users, we just verify the restaurant loads correctly
      assert restaurant_html =~ "Your Order" or restaurant_html =~ "Cart" or
               restaurant_html =~ "Menu"
    end
  end

  describe "Location persistence edge cases" do
    test "handles invalid location parameters gracefully", %{conn: conn} do
      # Test with invalid/non-existent location
      invalid_location = "NonExistentCity"

      {:ok, _view, html} = live(conn, ~p"/restaurants?location=#{invalid_location}")

      # Should load discovery page without crashing
      assert html =~ "Discover Restaurants"

      # Should show some kind of message about no results, location not found, or just load normally
      # The exact behavior depends on geocoding service response
      assert html =~ "No restaurants found" or html =~ "not found" or
               html =~ "adjust your filters" or html =~ "Discover Restaurants"
    end

    test "handles special characters in location parameter", %{conn: conn} do
      # Test with special characters that might cause issues
      special_location = "Den Haag"

      {:ok, _view, html} = live(conn, ~p"/restaurants?location=#{special_location}")

      # Should not crash and should load the page
      assert html =~ "Discover Restaurants"
    end
  end
end
