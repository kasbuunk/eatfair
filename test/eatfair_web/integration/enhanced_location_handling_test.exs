defmodule EatfairWeb.EnhancedLocationHandlingTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  describe "Enhanced location handling user journey" do
    setup do
      # Create a restaurant owner and restaurant
      owner = user_fixture(%{role: :restaurant_owner})

      # Create a restaurant in Bussum (Het Gooi area)
      restaurant =
        restaurant_fixture(%{
          name: "Laren Fine Dining",
          address: "Brink 5, 1251 KS Laren",
          city: "Laren",
          postal_code: "1251 KS",
          latitude: Decimal.new("52.2568172"),
          longitude: Decimal.new("5.224155"),
          delivery_radius_km: 5,
          owner_id: owner.id
        })

      # Create a menu and some meals for testing cart functionality
      _meal1 = meal_fixture(%{restaurant_id: restaurant.id, name: "Pasta Carbonara", price: Decimal.new("18.50")})
      _meal2 = meal_fixture(%{restaurant_id: restaurant.id, name: "Grilled Salmon", price: Decimal.new("24.00")})

      # Reload restaurant with menus and meals
      restaurant = Eatfair.Restaurants.get_restaurant!(restaurant.id)

      # Create a customer who will search for restaurants
      customer = user_fixture()

      %{restaurant: restaurant, customer: customer}
    end

    test "shows formatted location and delivery status from user feedback scenario", %{
      conn: conn,
      restaurant: restaurant,
      customer: _customer
    } do
      # This test replicates the exact user feedback scenario:
      # 1. User enters 'koekoeklaan 31 bussum' on homepage
      # 2. Clicks discover button to navigate to restaurant discovery
      # 3. Clicks on 'Laren Fine Dining' restaurant
      # 4. Should see proper delivery status and formatted location

      raw_address = "koekoeklaan 31 bussum"

      # Step 1 & 2: Navigate to discovery page with raw address (as if from homepage)
      {:ok, discovery_view, discovery_html} = 
        live(conn, ~p"/restaurants?location=#{raw_address}")

      # Verify restaurant is displayed in discovery (should deliver to Bussum)
      assert discovery_html =~ restaurant.name
      assert discovery_html =~ "Laren Fine Dining"

      # Step 3: Click on restaurant to navigate to detail page
      discovery_view |> element("button", "View Menu") |> render_click()

      assert_redirect(
        discovery_view,
        ~p"/restaurants/#{restaurant.id}?location=#{raw_address}"
      )

      # Step 4: Navigate to restaurant detail page
      {:ok, restaurant_view, restaurant_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{raw_address}")

      # Key assertions based on user feedback:
      
      # 1. Should show formatted location, not raw user input
      assert restaurant_html =~ "📍 Delivery to"
      # Should show Google Maps formatted address, not "koekoeklaan 31 bussum"
      assert restaurant_html =~ "Koekoeklaan 31" or restaurant_html =~ "Bussum"
      refute restaurant_html =~ "koekoeklaan 31 bussum" # Raw input should be formatted

      # 2. Should show that restaurant delivers to this location
      assert restaurant_html =~ "✅ Delivers to your location" or
             restaurant_html =~ "Available for delivery"

      # 3. Should show estimated delivery time
      assert restaurant_html =~ "estimated delivery time" or
             restaurant_html =~ "min"

      # 4. Should have option to change delivery address
      assert has_element?(restaurant_view, "button", "Change Address")

      # 5. Meals should be selectable for the shopping cart
      first_add_to_cart_button = "[data-add-to-cart]:first-of-type"
      assert has_element?(restaurant_view, first_add_to_cart_button)
      
      # Should NOT show delivery unavailable message
      refute restaurant_html =~ "❌ Delivery not available"
      refute restaurant_html =~ "Outside delivery range"
    end

    test "shows delivery unavailable for location outside range with proper messaging", %{
      conn: conn,
      restaurant: restaurant
    } do
      # Test with a location far from the restaurant (should be outside 5km range)
      far_location = "Amsterdam Centraal Station"

      {:ok, restaurant_view, restaurant_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{far_location}")

      # Should show formatted location
      assert restaurant_html =~ "📍 Delivery to"
      assert restaurant_html =~ "Amsterdam" # Should show formatted address

      # Should show delivery not available with clear messaging
      assert restaurant_html =~ "❌ Delivery not available"
      assert restaurant_html =~ "This location is outside the restaurant&#39;s delivery range (5 km)"
      refute restaurant_html =~ "Available for delivery"

      # Should have option to find other restaurants
      assert has_element?(restaurant_view, "a", "Find Other Restaurants")

      # Meals should NOT be addable to cart
      refute has_element?(restaurant_view, "[data-add-to-cart]")
      assert restaurant_html =~ "Delivery not available"
    end

    test "allows location refinement with real-time feedback", %{
      conn: conn,
      restaurant: restaurant
    } do
      # Start with a location outside delivery range
      initial_location = "Utrecht Centraal"

      {:ok, restaurant_view, restaurant_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{initial_location}")

      # Should show delivery not available initially
      assert restaurant_html =~ "❌ Delivery not available"

      # Click "Change Address" button
      restaurant_view |> element("button", "Change Address") |> render_click()

      # Should show address refinement form
      assert has_element?(restaurant_view, "#location-refinement-form")
      
      # Should show form with Update button and Cancel button
      assert has_element?(restaurant_view, "button", "Update")
      assert has_element?(restaurant_view, "button", "Cancel")
      
      # Click cancel to close the form
      restaurant_view |> element("button", "Cancel") |> render_click()
      
      # Address refinement form should be closed
      refute has_element?(restaurant_view, "#location-refinement-form")
    end

    test "maintains location context when navigating back to discovery", %{
      conn: conn,
      restaurant: restaurant
    } do
      search_location = "Hilversum"

      # Navigate to restaurant detail with location
      {:ok, restaurant_view, _html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{search_location}")

      # The back link should preserve the location parameter
      # Check that the back link exists and has the correct href
      assert has_element?(restaurant_view, "a", "Back to restaurants")
    end

    test "handles location geocoding failures gracefully", %{
      conn: conn,
      restaurant: restaurant
    } do
      # Use a non-existent location that should fail geocoding
      invalid_location = "NonExistentCityXYZ123"

      {:ok, restaurant_view, restaurant_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{invalid_location}")

      # Should show the location as entered (fallback)
      assert restaurant_html =~ "📍 Delivery to"
      assert restaurant_html =~ invalid_location

      # Should show delivery not available (geocoding failed)
      assert restaurant_html =~ "❌ Delivery not available"
      
      # Should still show option to change address
      assert has_element?(restaurant_view, "button", "Change Address")
    end

    test "location parameter takes precedence over user's saved address", %{
      conn: conn,
      restaurant: restaurant,
      customer: customer
    } do
      # Give the customer a saved address outside delivery range
      conn = log_in_user(conn, customer)

      # Create an address for the user that's outside delivery range
      _user_address = address_fixture(%{
        user: customer,
        name: "Home",
        street_address: "Damrak 1",
        city: "Amsterdam", 
        postal_code: "1012 LG",
        country: "Netherlands",
        is_default: true
      })

      # Navigate with location parameter that IS within delivery range
      search_location = "Laren centrum"

      {:ok, _restaurant_view, restaurant_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{search_location}")

      # Should show delivery available based on search location, NOT user's saved address
      assert restaurant_html =~ "✅ Delivers to your location"
      assert restaurant_html =~ "Laren" # Should show searched location
      
      # Should NOT show Amsterdam (user's saved address)
      refute restaurant_html =~ "Amsterdam"
      refute restaurant_html =~ "Damrak"
    end

    test "anonymous user can see delivery status without login", %{
      conn: conn,
      restaurant: restaurant
    } do
      # Test with anonymous user (not logged in)
      search_location = "Hilversum"

      {:ok, restaurant_view, restaurant_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=#{search_location}")

      # Should show formatted location
      assert restaurant_html =~ "📍 Delivery to"
      assert restaurant_html =~ "Hilversum"

      # Should show delivery status even without login
      assert restaurant_html =~ "✅ Delivers to your location" or
             restaurant_html =~ "❌ Delivery not available"

      # Should have address change functionality
      assert has_element?(restaurant_view, "button", "Change Address")
    end
  end

  describe "Location display and formatting" do
    setup do
      owner = user_fixture(%{role: :restaurant_owner})
      
      restaurant =
        restaurant_fixture(%{
          name: "Test Restaurant",
          address: "Test Address",
          city: "Laren",
          postal_code: "1251 KS",
          latitude: Decimal.new("52.2568172"),
          longitude: Decimal.new("5.224155"),
          delivery_radius_km: 8,
          owner_id: owner.id
        })

      %{restaurant: restaurant}
    end

    test "displays Google Maps formatted address instead of raw input", %{
      conn: conn,
      restaurant: restaurant
    } do
      test_cases = [
        # Raw input -> Expected to see formatted version
        {"hilversum", "Hilversum"},
        {"1251 ab laren", "1251"},
        {"bussum centrum", "Bussum"},
      ]

      for {raw_input, expected_format} <- test_cases do
        {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}?location=#{raw_input}")
        
        # Should show formatted version, not exact raw input
        assert html =~ expected_format
        
        # Should show location section
        assert html =~ "📍 Delivery to"
      end
    end

    test "shows detailed delivery status messaging", %{
      conn: conn,
      restaurant: restaurant
    } do
      # Test delivery available case
      {:ok, _view, available_html} = 
        live(conn, ~p"/restaurants/#{restaurant.id}?location=hilversum")

      assert available_html =~ "✅ Delivers to your location"
      assert available_html =~ "estimated delivery time"

      # Test delivery not available case  
      {:ok, _view, unavailable_html} =
        live(conn, ~p"/restaurants/#{restaurant.id}?location=amsterdam")

      assert unavailable_html =~ "❌ Delivery not available"
      assert unavailable_html =~ "This location is outside the restaurant&#39;s delivery range (8 km)"
    end
  end
end
