defmodule EatfairWeb.RestaurantLive.FilterCompositionBugTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.RestaurantsFixtures

  describe "Restaurant Filter Composition Bug" do
    setup do
      # Create restaurants in different locations to test filtering
      laren_restaurant =
        restaurant_fixture(%{
          name: "Laren Fine Dining",
          city: "Laren",
          address: "Brink 1, 1251 KL Laren",
          # Near Bussum
          latitude: Decimal.new("52.2576"),
          longitude: Decimal.new("5.2278"),
          delivery_radius_km: 8,
          is_open: true
        })

      london_restaurant =
        restaurant_fixture(%{
          name: "London Fish & Chips",
          city: "London",
          address: "Oxford Street 1, London",
          # Far from Bussum
          latitude: Decimal.new("51.5074"),
          longitude: Decimal.new("-0.1278"),
          delivery_radius_km: 5,
          is_open: true
        })

      amsterdam_restaurant =
        restaurant_fixture(%{
          name: "Amsterdam Fika",
          city: "Amsterdam",
          address: "Dam 1, 1012 JS Amsterdam",
          # Far from Bussum but closer than London
          latitude: Decimal.new("52.3702"),
          longitude: Decimal.new("4.8952"),
          delivery_radius_km: 15,
          is_open: true
        })

      %{
        laren_restaurant: laren_restaurant,
        london_restaurant: london_restaurant,
        amsterdam_restaurant: amsterdam_restaurant
      }
    end

    test "CRITICAL BUG: location filter gets dropped when typing restaurant name", %{
      conn: conn,
      laren_restaurant: laren_restaurant,
      london_restaurant: london_restaurant,
      amsterdam_restaurant: amsterdam_restaurant
    } do
      # Navigate to discovery page
      {:ok, lv, _html} = live(conn, "/restaurants")

      # Step 1: Set location to Bussum (near Laren, far from London)
      send(lv.pid, {"location_autocomplete_selected", "Brink 1, 1251 KL Bussum"})

      html_after_location = render(lv)

      # Should show flash message about location
      assert html_after_location =~ "Showing restaurants near"
      assert html_after_location =~ "Bussum"

      # Should show Laren restaurant (nearby) and not show London restaurant (too far)
      assert has_element?(lv, "#restaurant-#{laren_restaurant.id}")
      refute has_element?(lv, "#restaurant-#{london_restaurant.id}")

      # Step 2: Type "fi" in restaurant search (matches both "Fine" in Laren and "Fish" in London)
      lv
      |> element("#restaurant-search")
      |> render_keyup(%{"value" => "fi"})

      html_after_search = render(lv)

      # BUG REPRODUCTION: Location filter should still be active!
      # Should ONLY show Laren Fine Dining (nearby + matches "fi")
      # Should NOT show London Fish & Chips (far away, location filter should exclude it)

      # EXPECTED BEHAVIOR (currently fails):
      assert has_element?(lv, "#restaurant-#{laren_restaurant.id}"),
             "Laren Fine Dining should still be visible (nearby AND matches 'fi')"

      # CURRENT BUG (this passes incorrectly):
      refute has_element?(lv, "#restaurant-#{london_restaurant.id}"),
             "London Fish & Chips should NOT be visible (too far from Bussum location filter)"

      # Amsterdam restaurant should not be visible (doesn't match "fi" search)
      refute has_element?(lv, "#restaurant-#{amsterdam_restaurant.id}")

      # Verify the location is still set in the socket
      # The location should persist throughout filter operations
      assert html_after_search =~ "Bussum" or html_after_search =~ "location"
    end

    test "location filter should persist when clearing restaurant search", %{
      conn: conn,
      laren_restaurant: laren_restaurant,
      london_restaurant: london_restaurant
    } do
      {:ok, lv, _html} = live(conn, "/restaurants")

      # Set location filter
      send(lv.pid, {"location_autocomplete_selected", "Brink 1, 1251 KL Bussum"})

      # Type in search 
      lv
      |> element("#restaurant-search")
      |> render_keyup(%{"value" => "fish"})

      # Clear search
      lv
      |> element("#restaurant-search")
      |> render_keyup(%{"value" => ""})

      _html_after_clear = render(lv)

      # Location filter should still be active - only show nearby restaurants
      assert has_element?(lv, "#restaurant-#{laren_restaurant.id}")
      refute has_element?(lv, "#restaurant-#{london_restaurant.id}")
    end

    test "multiple filters should compose correctly with location", %{
      conn: conn,
      laren_restaurant: laren_restaurant,
      london_restaurant: london_restaurant
    } do
      {:ok, lv, _html} = live(conn, "/restaurants")

      # Set location 
      send(lv.pid, {"location_autocomplete_selected", "Brink 1, 1251 KL Bussum"})

      # Toggle some filters
      lv |> element("input[phx-click='toggle_delivery_filter']") |> render_click()
      lv |> element("input[phx-click='toggle_open_filter']") |> render_click()

      # Add restaurant search
      lv
      |> element("#restaurant-search")
      |> render_keyup(%{"value" => "fi"})

      # Location filter should still be active throughout all filter changes
      assert has_element?(lv, "#restaurant-#{laren_restaurant.id}")
      refute has_element?(lv, "#restaurant-#{london_restaurant.id}")
    end
  end
end
