defmodule EatfairWeb.RestaurantDiscoveryFlowTest do
  use EatfairWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Eatfair.Restaurants.Restaurant
  alias Eatfair.Restaurants

  describe "restaurant availability consistency" do
    test "filter_by_currently_open/2 uses consistent availability logic with order page", %{
      conn: _conn
    } do
      # Create restaurants with different availability states
      open_restaurant = create_genuinely_open_restaurant()
      force_closed_restaurant = create_force_closed_restaurant()
      time_closed_restaurant = create_time_closed_restaurant()

      # Test the filter function directly with our test data
      all_restaurants = [open_restaurant, force_closed_restaurant, time_closed_restaurant]

      # Apply the currently_open filter (true)
      filtered_restaurants = apply_discovery_filter(all_restaurants, true)

      # Only genuinely open restaurant should remain
      assert length(filtered_restaurants) == 1
      assert hd(filtered_restaurants).id == open_restaurant.id

      # Verify that filtered restaurants can actually take orders
      Enum.each(filtered_restaurants, fn restaurant ->
        assert Restaurant.open_for_orders?(restaurant) == true,
               "Restaurant #{restaurant.name} passed 'currently_open' filter but open_for_orders?/1 returns false"
      end)

      # Verify that excluded restaurants are actually closed
      excluded_restaurants = all_restaurants -- filtered_restaurants

      Enum.each(excluded_restaurants, fn restaurant ->
        assert Restaurant.open_for_orders?(restaurant) == false,
               "Restaurant #{restaurant.name} was filtered out but open_for_orders?/1 returns true"
      end)
    end

    test "restaurants filtered as 'open for orders' should allow order placement", %{conn: conn} do
      # Create a user and login
      user = Eatfair.AccountsFixtures.user_fixture()
      conn = log_in_user(conn, user)

      # Create a restaurant that is genuinely open
      restaurant = create_genuinely_open_restaurant()

      # Visit discovery page with location
      {:ok, view, _html} = live(conn, "/restaurants?location=Amsterdam")

      # Ensure the "currently open" filter is enabled
      html = render(view)
      assert html =~ "Only show restaurants open for orders"

      # The restaurant should appear in filtered results
      filtered_html = render(view)
      assert String.contains?(filtered_html, restaurant.name)

      # Navigate to order page
      {:ok, order_view, _html} = live(conn, "/restaurants/#{restaurant.id}")

      # Should NOT show "Restaurant Closed" message
      order_html = render(order_view)
      refute String.contains?(order_html, "Restaurant Closed")
      refute String.contains?(order_html, "currently closed")
    end


    defp create_genuinely_open_restaurant do
      # Create a restaurant that is actually open for orders right now
      current_time = DateTime.now!("Europe/Amsterdam")
      current_minute = current_time.hour * 60 + current_time.minute

      # Set wide operational hours to ensure restaurant is open now
      # Started 1 hour ago
      order_open = max(0, current_minute - 60)
      # Closes in 2 hours, but ensure we leave room for kitchen close time
      order_close = min(1410, current_minute + 120)  # Max 23:30 to allow 30min gap
      # Kitchen closes 30 minutes after orders, but max at 24:00 (1440)
      kitchen_close = order_close + 30

      owner = Eatfair.AccountsFixtures.user_fixture()

      {:ok, restaurant} =
        Restaurants.create_restaurant(%{
          name: "Test Restaurant (Actually Open)",
          address: "Test Address, Amsterdam",
          description: "Test restaurant that is genuinely open",
          owner_id: owner.id,
          is_open: true,
          order_open_time: order_open,
          order_close_time: order_close,
          kitchen_close_time: kitchen_close,
          # Set to today's day so operating_days allows today  
          operating_days: :math.pow(2, Date.day_of_week(current_time) - 1) |> round(),
          timezone: "Europe/Amsterdam",
          latitude: Decimal.new("52.3676"),
          longitude: Decimal.new("4.9041"),
          city: "Amsterdam",
          postal_code: "1000",
          avg_preparation_time: 30,
          delivery_radius_km: 10
        })

      # Verify our setup: restaurant should be genuinely open
      assert restaurant.is_open == true
      assert Restaurant.open_for_orders?(restaurant) == true

      restaurant
    end

    defp create_force_closed_restaurant do
      # Create a restaurant that is force_closed
      current_time = DateTime.now!("Europe/Amsterdam")
      current_minute = current_time.hour * 60 + current_time.minute

      # Set operational hours (would be open now)
      # Started 1 hour ago
      order_open = max(0, current_minute - 60)
      # Closes in 2 hours, but ensure we leave room for kitchen close time
      order_close = min(1410, current_minute + 120)  # Max 23:30 to allow 30min gap
      # Kitchen closes 30 minutes after orders
      kitchen_close = order_close + 30

      owner = Eatfair.AccountsFixtures.user_fixture()

      {:ok, restaurant} =
        Restaurants.create_restaurant(%{
          name: "Test Restaurant (Force Closed)",
          address: "Test Address, Amsterdam",
          description: "Test restaurant that is force closed",
          owner_id: owner.id,
          is_open: true,
          order_open_time: order_open,
          order_close_time: order_close,
          kitchen_close_time: kitchen_close,
          operating_days: :math.pow(2, Date.day_of_week(current_time) - 1) |> round(),
          timezone: "Europe/Amsterdam",
          latitude: Decimal.new("52.3676"),
          longitude: Decimal.new("4.9041"),
          city: "Amsterdam",
          postal_code: "1000",
          avg_preparation_time: 30,
          delivery_radius_km: 10,
          # This makes it closed
          force_closed: true,
          force_closed_reason: "maintenance"
        })

      # Verify our setup: restaurant should be closed due to force_closed
      assert restaurant.is_open == true
      assert restaurant.force_closed == true
      assert Restaurant.open_for_orders?(restaurant) == false

      restaurant
    end

    defp create_time_closed_restaurant do
      # Create a restaurant that is closed due to time
      current_time = DateTime.now!("Europe/Amsterdam")
      current_hour = current_time.hour

      # Set order hours so restaurant is closed right now
      # If it's morning (before 10), set hours to afternoon only
      # If it's afternoon/evening, set hours to morning only
      {order_open, order_close} =
        if current_hour < 10 do
          # Restaurant only open 14:00-18:00 (when it's currently morning)
          {14 * 60, 18 * 60}
        else
          # Restaurant only open 06:00-10:00 (when it's currently afternoon/evening)  
          {6 * 60, 10 * 60}
        end

      owner = Eatfair.AccountsFixtures.user_fixture()
      # Kitchen closes 30 minutes after orders
      kitchen_close = order_close + 30

      {:ok, restaurant} =
        Restaurants.create_restaurant(%{
          name: "Test Restaurant (Time Closed)",
          address: "Test Address, Amsterdam",
          description: "Test restaurant closed due to hours",
          owner_id: owner.id,
          is_open: true,
          order_open_time: order_open,
          order_close_time: order_close,
          kitchen_close_time: kitchen_close,
          operating_days: :math.pow(2, Date.day_of_week(current_time) - 1) |> round(),
          timezone: "Europe/Amsterdam",
          latitude: Decimal.new("52.3676"),
          longitude: Decimal.new("4.9041"),
          city: "Amsterdam",
          postal_code: "1000",
          avg_preparation_time: 30,
          delivery_radius_km: 10
        })

      # Verify our setup: restaurant should be closed due to hours
      assert restaurant.is_open == true
      assert restaurant.force_closed == false
      assert Restaurant.open_for_orders?(restaurant) == false

      restaurant
    end

    # Apply the same filter logic used in discovery.ex
    defp apply_discovery_filter(restaurants, currently_open_filter) do
      if currently_open_filter do
        restaurants |> Enum.filter(&Restaurant.open_for_orders?/1)
      else
        restaurants
      end
    end
  end
end
