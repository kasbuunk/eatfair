defmodule EatfairWeb.RestaurantLive.AnonymousCartFixTest do
  use EatfairWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Eatfair.RestaurantsFixtures

  setup do
    # Create a test restaurant with menu and meals
    restaurant = RestaurantsFixtures.restaurant_fixture()
    meal1 = RestaurantsFixtures.meal_fixture(%{restaurant_id: restaurant.id, name: "Test Meal 1", price: Decimal.new("10.00")})
    meal2 = RestaurantsFixtures.meal_fixture(%{restaurant_id: restaurant.id, name: "Test Meal 2", price: Decimal.new("15.00")})
    
    # Reload the restaurant with menus and meals
    restaurant = Eatfair.Restaurants.get_restaurant!(restaurant.id)
    
    %{restaurant: restaurant, meal1: meal1, meal2: meal2}
  end

  describe "anonymous user cart functionality" do
    test "anonymous user can view restaurant page without crashes - the original bug fix", %{conn: conn, restaurant: restaurant} do
      # This test verifies the original fix: the template should not crash when current_scope is nil
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")
      
      # Should display restaurant name without errors (this would have crashed before the fix)
      assert html =~ restaurant.name
      
      # Should display menus and meals without crashing
      assert html =~ "Menu"
      assert html =~ "Test Meal 1"
      assert html =~ "Test Meal 2"
      
      # Should show restaurant details
      assert html =~ "Test Street 123, Amsterdam"
      assert html =~ "Delivery: 30 min"
      assert html =~ "Min order: $15.00"
      
      # Should show cart section (though may be empty or with no delivery available message)
      assert html =~ "Your Order"
    end

    test "anonymous user with location can potentially see cart buttons", %{conn: conn, restaurant: restaurant} do
      # Test with a location parameter that might enable delivery
      location = "Amsterdam"
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}?location=#{location}")
      
      # Should render without crashes
      assert html =~ restaurant.name
      assert html =~ "Delivery to"
      
      # May show delivery availability depending on restaurant's delivery range
      # This is not the main focus - the important thing is it doesn't crash
    end

    test "template handles nil current_scope gracefully throughout", %{conn: conn, restaurant: restaurant} do
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")
      
      # Core test: page renders without server errors
      # Before the fix, this would crash with "key :user not found in: nil"
      assert html =~ restaurant.name
      
      # Should still render restaurant content
      assert html =~ "Menu"
      assert html =~ "Customer Reviews"
      assert html =~ "Your Order"
      
      # Should not show authenticated user-specific content
      refute html =~ "Available for delivery"
      refute html =~ "review this restaurant"
      
      # But should show general delivery status for anonymous users
      assert html =~ "Delivery not available" or html =~ "Outside delivery range"
    end

    test "anonymous user page navigation works", %{conn: conn, restaurant: restaurant} do
      {:ok, view, _html} = live(conn, ~p"/restaurants/#{restaurant.id}")
      
      # Should be able to navigate back without issues
      assert has_element?(view, "a", "Back to restaurants")
      
      # Should not crash when trying to access review functionality as anonymous
      # (though it won't show review form)
      refute has_element?(view, "[data-testid='add-review-button']")
    end

    test "restaurant page loads with empty cart state for anonymous users", %{conn: conn, restaurant: restaurant} do
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")
      
      # Should show empty cart
      assert html =~ "Your cart is empty"
      assert html =~ "Add some delicious items!"
      
      # Should not show checkout options without items
      refute html =~ "Checkout"
    end
  end
end
