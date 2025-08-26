defmodule EatfairWeb.RatingDisplayTest do
  use EatfairWeb.ConnCase
  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures
  import Eatfair.OrdersFixtures
  
  alias Eatfair.Reviews

  describe "Rating Average Display" do
    setup do
      # Create a restaurant owner and restaurant
      owner = user_fixture(%{role: :restaurant_owner})
      restaurant = restaurant_fixture(%{owner_id: owner.id})

      # Create customers who will leave reviews
      customer1 = user_fixture()
      customer2 = user_fixture()
      customer3 = user_fixture()

      # Create completed orders for each customer
      order1 = order_fixture(%{restaurant_id: restaurant.id, customer_id: customer1.id, status: "delivered"})
      order2 = order_fixture(%{restaurant_id: restaurant.id, customer_id: customer2.id, status: "delivered"})
      order3 = order_fixture(%{restaurant_id: restaurant.id, customer_id: customer3.id, status: "delivered"})

      # Create reviews
      {:ok, _review1} = Reviews.create_review(%{
        rating: 5,
        comment: "Excellent food!",
        user_id: customer1.id,
        restaurant_id: restaurant.id,
        order_id: order1.id
      })

      {:ok, _review2} = Reviews.create_review(%{
        rating: 4,
        comment: "Pretty good",
        user_id: customer2.id,
        restaurant_id: restaurant.id,
        order_id: order2.id
      })

      {:ok, _review3} = Reviews.create_review(%{
        rating: 3,
        comment: "Average experience",
        user_id: customer3.id,
        restaurant_id: restaurant.id,
        order_id: order3.id
      })

      %{
        restaurant: restaurant,
        customer1: customer1,
        expected_average: 4.0  # (5+4+3)/3 = 4.0
      }
    end

    test "restaurant discovery shows rating averages with one decimal point", %{conn: conn, restaurant: restaurant} do
      {:ok, lv, html} = live(conn, ~p"/restaurants/discover")
      
      # Should show the calculated average rating with one decimal point
      assert html =~ "4.0 (3 reviews)"
      assert html =~ restaurant.name
    end

    test "restaurant detail page shows rating averages with one decimal point", %{conn: conn, restaurant: restaurant} do
      {:ok, lv, html} = live(conn, ~p"/restaurants/#{restaurant.id}")
      
      # Should show the calculated average rating with one decimal point
      assert html =~ "4.0"
      assert html =~ "(3 reviews)"
    end

    test "restaurants without reviews do not show rating display", %{conn: conn} do
      # Create a restaurant without reviews
      owner = user_fixture(%{role: :restaurant_owner})
      restaurant_no_reviews = restaurant_fixture(%{owner_id: owner.id})

      {:ok, lv, html} = live(conn, ~p"/restaurants/discover")
      
      # Should not show rating for restaurant without reviews
      refute html =~ "0.0 (0 reviews)"
      # But should still show the restaurant
      assert html =~ restaurant_no_reviews.name
    end

    test "core component format_average_rating formats correctly" do
      # Test the shared helper function
      assert EatfairWeb.CoreComponents.format_average_rating(nil) == "0.0"
      assert EatfairWeb.CoreComponents.format_average_rating(4.0) == "4.0"
      assert EatfairWeb.CoreComponents.format_average_rating(4.5) == "4.5"
      assert EatfairWeb.CoreComponents.format_average_rating(4.67) == "4.7"
      assert EatfairWeb.CoreComponents.format_average_rating(3.33) == "3.3"
    end
  end
end
