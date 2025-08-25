defmodule EatfairWeb.Integration.RestaurantDiscoveryTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  describe "🗺️ Location-Based Restaurant Discovery" do
    setup do
      # Create test customer with address in Amsterdam
      customer = confirmed_user_fixture(%{
        name: "Amsterdam Customer", 
        email: "customer@amsterdam.nl",
        default_address: "Damrak 1, 1012 LG Amsterdam"
      })
      
      # Create restaurants in different locations
      amsterdam_restaurant = restaurant_fixture(%{
        name: "Amsterdam Bistro",
        address: "Nieuwmarkt 10, 1012 CR Amsterdam", 
        latitude: Decimal.new("52.3702"),
        longitude: Decimal.new("4.9002"),
        city: "Amsterdam",
        postal_code: "1012 CR",
        delivery_radius_km: 5
      })
      
      # Utrecht restaurant (should be filtered out for Amsterdam customer)
      utrecht_restaurant = restaurant_fixture(%{
        name: "Utrecht Cafe",
        address: "Oudegracht 100, 3511 AZ Utrecht",
        latitude: Decimal.new("52.0907"),
        longitude: Decimal.new("5.1214"), 
        city: "Utrecht",
        postal_code: "3511 AZ",
        delivery_radius_km: 8
      })
      
      %{
        customer: customer,
        amsterdam_restaurant: amsterdam_restaurant,
        utrecht_restaurant: utrecht_restaurant
      }
    end

    test "📍 customer sees restaurants within delivery radius of their location", 
         %{conn: conn, customer: customer, amsterdam_restaurant: amsterdam_restaurant, utrecht_restaurant: utrecht_restaurant} do
      
      conn = log_in_user(conn, customer)
      
      # Navigate to restaurant discovery page
      {:ok, discovery_live, html} = live(conn, "/restaurants/discover")
      
      # Should see Amsterdam restaurant (nearby)
      assert has_element?(discovery_live, "#restaurant-#{amsterdam_restaurant.id}")
      assert html =~ "Amsterdam Bistro"
      
      # Should NOT see Utrecht restaurant (too far)
      refute has_element?(discovery_live, "#restaurant-#{utrecht_restaurant.id}")
      refute html =~ "Utrecht Cafe"
    end

    test "🔍 customer can search by location", %{conn: conn, customer: customer} do
      conn = log_in_user(conn, customer)
      {:ok, discovery_live, _html} = live(conn, "/restaurants/discover")
      
      # Search for restaurants in Utrecht
      discovery_live
      |> form("#location-search", location: %{address: "Utrecht, Netherlands"})
      |> render_submit()
      
      # Should update results to show Utrecht restaurants
      assert has_element?(discovery_live, "[data-testid='search-results-utrecht']")
    end

    test "🏷️ customer can filter by cuisine type", %{conn: conn, customer: customer} do
      # Create restaurants with different cuisines
      italian_restaurant = restaurant_fixture(%{
        name: "Italian Place",
        latitude: Decimal.new("52.3702"),
        longitude: Decimal.new("4.9002"),
        city: "Amsterdam"
      })
      
      chinese_restaurant = restaurant_fixture(%{
        name: "Chinese Place", 
        latitude: Decimal.new("52.3712"),
        longitude: Decimal.new("4.9012"),
        city: "Amsterdam"
      })
      
      # Associate with cuisines
      italian_cuisine = cuisine_fixture(%{name: "Italian"})
      chinese_cuisine = cuisine_fixture(%{name: "Chinese"})
      
      # Associate restaurants with their cuisines
      associate_restaurant_cuisines(italian_restaurant, italian_cuisine)
      associate_restaurant_cuisines(chinese_restaurant, chinese_cuisine)
      
      conn = log_in_user(conn, customer)
      {:ok, discovery_live, _html} = live(conn, "/restaurants/discover")
      
      # Filter by Italian cuisine
      discovery_live
      |> element("#cuisine-filter")
      |> render_change(%{cuisine: "Italian"})
      
      # Should only show Italian restaurants
      assert has_element?(discovery_live, "#restaurant-#{italian_restaurant.id}")
      refute has_element?(discovery_live, "#restaurant-#{chinese_restaurant.id}")
    end

    test "💰 customer can filter by price range", %{conn: conn, customer: customer} do
      # Create restaurants with different price ranges
      budget_restaurant = restaurant_fixture(%{
        name: "Budget Eats",
        min_order_value: Decimal.new("10.00"),
        latitude: Decimal.new("52.3702"),
        longitude: Decimal.new("4.9002"),
        city: "Amsterdam"
      })
      
      expensive_restaurant = restaurant_fixture(%{
        name: "Fine Dining",
        min_order_value: Decimal.new("50.00"),
        latitude: Decimal.new("52.3712"), 
        longitude: Decimal.new("4.9012"),
        city: "Amsterdam"
      })
      
      conn = log_in_user(conn, customer)
      {:ok, discovery_live, _html} = live(conn, "/restaurants/discover")
      
      # Filter by budget price range (under €20)
      discovery_live
      |> element("#price-filter") 
      |> render_change(%{max_price: "20"})
      
      # Should only show budget restaurant
      assert has_element?(discovery_live, "#restaurant-#{budget_restaurant.id}")
      refute has_element?(discovery_live, "#restaurant-#{expensive_restaurant.id}")
    end

    test "⏱️ customer can filter by delivery time", %{conn: conn, customer: customer} do
      # Create restaurants with different delivery times
      fast_restaurant = restaurant_fixture(%{
        name: "Fast Food",
        avg_preparation_time: 15,
        latitude: Decimal.new("52.3702"),
        longitude: Decimal.new("4.9002"), 
        city: "Amsterdam"
      })
      
      slow_restaurant = restaurant_fixture(%{
        name: "Slow Food",
        avg_preparation_time: 60,
        latitude: Decimal.new("52.3712"),
        longitude: Decimal.new("4.9012"),
        city: "Amsterdam" 
      })
      
      conn = log_in_user(conn, customer)
      {:ok, discovery_live, _html} = live(conn, "/restaurants/discover")
      
      # Filter by delivery time (under 30 minutes)
      discovery_live
      |> element("#delivery-time-filter")
      |> render_change(%{max_delivery_time: "30"})
      
      # Should only show fast restaurant
      assert has_element?(discovery_live, "#restaurant-#{fast_restaurant.id}")
      refute has_element?(discovery_live, "#restaurant-#{slow_restaurant.id}")
    end

    test "🚫 shows appropriate message when no restaurants match filters", %{conn: conn, customer: customer} do
      conn = log_in_user(conn, customer)
      {:ok, discovery_live, _html} = live(conn, "/restaurants/discover")
      
      # Apply very restrictive filters
      discovery_live
      |> element("#cuisine-filter") 
      |> render_change(%{cuisine: "NonexistentCuisine"})
      
      # Should show no results message
      assert has_element?(discovery_live, "[data-testid='no-results-message']")
      assert render(discovery_live) =~ "No restaurants found matching your criteria"
    end

    test "📱 search results update in real-time as user types", %{conn: conn, customer: customer} do
      restaurant = restaurant_fixture(%{
        name: "Searchable Restaurant",
        latitude: Decimal.new("52.3702"),
        longitude: Decimal.new("4.9002"),
        city: "Amsterdam"
      })
      
      conn = log_in_user(conn, customer) 
      {:ok, discovery_live, _html} = live(conn, "/restaurants/discover")
      
      # Type in search box - should update results without form submit
      discovery_live
      |> element("#restaurant-search")
      |> render_hook("search", %{query: "Searchable"})
      
      # Should show matching restaurant
      assert has_element?(discovery_live, "#restaurant-#{restaurant.id}")
      
      # Clear search - should show all restaurants again
      discovery_live
      |> element("#restaurant-search")
      |> render_hook("search", %{query: ""})
      
      assert has_element?(discovery_live, "#restaurant-#{restaurant.id}")
    end
  end

  describe "🗺️ Address Management for Location-Based Search" do
    setup do
      customer = confirmed_user_fixture()
      %{customer: customer}
    end

    test "👤 customer can add a new address", %{conn: conn, customer: customer} do
      conn = log_in_user(conn, customer)
      {:ok, profile_live, _html} = live(conn, "/users/addresses")
      
      # Click add address
      profile_live |> element("#add-address-button") |> render_click()
      
      # Fill out address form
      profile_live
      |> form("#address-form", address: %{
        name: "Home", 
        street_address: "Prinsengracht 100, Amsterdam",
        city: "Amsterdam",
        postal_code: "1015 EA",
        is_default: true
      })
      |> render_submit()
      
      # Should see success message and new address
      assert render(profile_live) =~ "Address saved successfully"
      assert has_element?(profile_live, "[data-testid='address-home']")
    end

    test "📍 customer can set default address for restaurant discovery", %{conn: conn, customer: customer} do
      conn = log_in_user(conn, customer)
      {:ok, profile_live, _html} = live(conn, "/users/addresses")
      
      # Add first address - Show form first
      profile_live |> element("#add-address-button") |> render_click()
      
      profile_live
      |> form("#address-form", address: %{
        name: "Work",
        street_address: "Herengracht 200, Amsterdam", 
        city: "Amsterdam",
        postal_code: "1016 BS"
      })
      |> render_submit()
      
      # Add second address - Show form again
      profile_live |> element("#add-address-button") |> render_click()
      
      profile_live
      |> form("#address-form", address: %{
        name: "Home",
        street_address: "Damrak 50, Amsterdam",
        city: "Amsterdam", 
        postal_code: "1012 LL"
      })
      |> render_submit()
      
      # Set Home as default
      profile_live
      |> element("#address-home .set-default-button")
      |> render_click()
      
      # Should show Home as default address
      assert has_element?(profile_live, "#address-home [data-testid='default-address-badge']")
    end
  end

  describe "🧭 Distance-Based Delivery Validation" do 
    setup do
      customer = confirmed_user_fixture(%{
        default_address: "Damrak 1, Amsterdam"  # Central Amsterdam
      })
      
      # Restaurant with 3km delivery radius
      close_restaurant = restaurant_fixture(%{
        name: "Close Restaurant",
        address: "Nieuwmarkt 10, Amsterdam", # ~1km from Damrak
        latitude: Decimal.new("52.3702"),
        longitude: Decimal.new("4.9002"), 
        delivery_radius_km: 3
      })
      
      # Restaurant with small delivery radius that doesn't reach customer
      far_restaurant = restaurant_fixture(%{
        name: "Far Restaurant", 
        address: "Amstelpark 1, Amsterdam", # ~5km from Damrak
        latitude: Decimal.new("52.3400"),
        longitude: Decimal.new("4.8900"),
        delivery_radius_km: 2  # Too small to reach customer
      })
      
      %{customer: customer, close_restaurant: close_restaurant, far_restaurant: far_restaurant}
    end

    test "✅ restaurant within delivery radius accepts orders", 
         %{conn: conn, customer: customer, close_restaurant: close_restaurant} do
      
      conn = log_in_user(conn, customer)
      {:ok, restaurant_live, _html} = live(conn, "/restaurants/#{close_restaurant.id}")
      
      # Should be able to order from this restaurant 
      assert has_element?(restaurant_live, "[data-testid='order-button']")
      assert render(restaurant_live) =~ "Available for delivery"
    end

    test "❌ restaurant outside delivery radius shows unavailable message",
         %{conn: conn, customer: customer, far_restaurant: far_restaurant} do
      
      conn = log_in_user(conn, customer)
      {:ok, restaurant_live, _html} = live(conn, "/restaurants/#{far_restaurant.id}")
      
      # Should show delivery unavailable message
      refute has_element?(restaurant_live, "[data-testid='order-button']")
      assert render(restaurant_live) =~ "Delivery not available to your location"
    end
  end
end
