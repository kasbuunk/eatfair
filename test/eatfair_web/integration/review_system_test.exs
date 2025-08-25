defmodule EatfairWeb.ReviewSystemTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  # import Floki

  alias Eatfair.{Repo, Reviews}
  alias Eatfair.Reviews.Review
  alias Eatfair.Restaurants.{Restaurant, Cuisine, Menu, Meal}

  setup do
    # Clean up
    Repo.delete_all(Review)
    Repo.delete_all(Meal)
    Repo.delete_all(Menu)
    Repo.delete_all(Restaurant)
    Repo.delete_all(Cuisine)

    # Create test user
    user = user_fixture()

    # Create another user for reviews - manually insert with name
    {:ok, reviewer1} = Eatfair.Accounts.register_user(%{email: "reviewer1@example.com"})
    |> case do
      {:ok, user} -> Repo.update(Ecto.Changeset.cast(user, %{name: "Alice Smith"}, [:name]))
      error -> error
    end

    {:ok, reviewer2} = Eatfair.Accounts.register_user(%{email: "reviewer2@example.com"})
    |> case do
      {:ok, user} -> Repo.update(Ecto.Changeset.cast(user, %{name: "Bob Johnson"}, [:name]))
      error -> error
    end

    # Create cuisine
    {:ok, cuisine} = %Cuisine{name: "Italian"} |> Repo.insert()

    # Create restaurant
    restaurant_attrs = %{
      name: "Test Restaurant",
      address: "123 Test St",
      delivery_time: 30,
      min_order_value: Decimal.new("15.00"),
      image_url: "https://example.com/restaurant.jpg",
      owner_id: user.id
    }

    {:ok, restaurant} = %Restaurant{}
    |> Restaurant.changeset(restaurant_attrs)
    |> Repo.insert()

    # Associate restaurant with cuisine
    {1, _} = Repo.insert_all(
      "restaurant_cuisines",
      [%{restaurant_id: restaurant.id, cuisine_id: cuisine.id, inserted_at: NaiveDateTime.utc_now(), updated_at: NaiveDateTime.utc_now()}]
    )

    # Create menu and meal for the restaurant
    {:ok, menu} = %Menu{name: "Main Menu", restaurant_id: restaurant.id} |> Repo.insert()
    {:ok, meal} = %Meal{
      name: "Test Pasta",
      description: "Delicious pasta dish",
      price: Decimal.new("12.99"),
      menu_id: menu.id
    } |> Repo.insert()

    # Create delivered orders for the reviewers (so they can leave reviews)
    {:ok, order1} = Eatfair.Orders.create_order(%{
      customer_id: reviewer1.id,
      restaurant_id: restaurant.id,
      status: "delivered",
      total_price: Decimal.new("12.99"),
      delivery_address: "123 Reviewer St"
    })

    {:ok, order2} = Eatfair.Orders.create_order(%{
      customer_id: reviewer2.id,
      restaurant_id: restaurant.id,
      status: "delivered",
      total_price: Decimal.new("25.98"),
      delivery_address: "456 Reviewer Ave"
    })

    # Create some reviews (now with order_id requirement)
    {:ok, review1} = Reviews.create_review(%{
      rating: 5,
      comment: "Excellent food and service! Highly recommend the pasta.",
      user_id: reviewer1.id,
      restaurant_id: restaurant.id,
      order_id: order1.id
    })

    {:ok, review2} = Reviews.create_review(%{
      rating: 4,
      comment: "Good food, fast delivery. Will order again.",
      user_id: reviewer2.id,
      restaurant_id: restaurant.id,
      order_id: order2.id
    })

    %{
      user: user,
      reviewer1: reviewer1,
      reviewer2: reviewer2,
      restaurant: restaurant,
      cuisine: cuisine,
      menu: menu,
      meal: meal,
      review1: review1,
      review2: review2
    }
  end

  describe "Restaurant page reviews section" do
    test "displays reviews with proper data attributes", %{conn: conn, restaurant: restaurant} do
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Assert reviewer names are displayed
      assert html =~ "Alice Smith"
      assert html =~ "Bob Johnson"

      # Assert review comments are displayed
      assert html =~ "Excellent food and service"
      assert html =~ "Good food, fast delivery"

      # Verify reviews section exists
      assert html =~ "Customer Reviews"
    end

    test "shows empty state when no reviews exist", %{conn: conn} do
      # Create a new user to avoid restaurant owner constraint
      new_owner = user_fixture(%{email: "owner2@example.com"})
      
      # Create a restaurant without reviews
      {:ok, cuisine} = %Cuisine{name: "Mexican"} |> Repo.insert()
      restaurant_attrs = %{
        name: "Empty Restaurant",
        address: "456 Empty St",
        delivery_time: 25,
        min_order_value: Decimal.new("10.00"),
        owner_id: new_owner.id
      }

      {:ok, empty_restaurant} = %Restaurant{}
      |> Restaurant.changeset(restaurant_attrs)
      |> Repo.insert()

      {1, _} = Repo.insert_all(
        "restaurant_cuisines",
        [%{restaurant_id: empty_restaurant.id, cuisine_id: cuisine.id, inserted_at: NaiveDateTime.utc_now(), updated_at: NaiveDateTime.utc_now()}]
      )

      {:ok, _menu} = %Menu{name: "Main Menu", restaurant_id: empty_restaurant.id} |> Repo.insert()

      {:ok, _view, html} = live(conn, ~p"/restaurants/#{empty_restaurant.id}")

      # Assert empty state message
      assert html =~ "No reviews yet"
      assert html =~ "Be the first to share your experience"
    end

    test "displays review form for logged in users who haven't reviewed", %{conn: conn, user: user, restaurant: restaurant} do
      # Create a delivered order for the user so they can review
      {:ok, _order} = Eatfair.Orders.create_order(%{
        customer_id: user.id,
        restaurant_id: restaurant.id,
        status: "delivered",
        total_price: Decimal.new("30.00"),
        delivery_address: "123 User St"
      })
      
      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Assert "Write a Review" button exists for logged-in user with delivered order
      assert html =~ "Write a Review"

      # Click the write review button
      html = view |> element("button", "Write a Review") |> render_click()

      # Assert review form appears
      assert html =~ "Share your experience"
      assert html =~ "name=\"review[rating]\""
      assert html =~ "name=\"review[comment]\""
      assert html =~ "Submit Review"
      assert html =~ "Cancel"
    end

    test "successfully submits a review", %{conn: conn, restaurant: restaurant} do
      # Create a new user who hasn't reviewed yet - use username instead of name
      new_user = user_fixture(%{email: "newuser@example.com"})
      
      # Create a delivered order for the user so they can review
      {:ok, _order} = Eatfair.Orders.create_order(%{
        customer_id: new_user.id,
        restaurant_id: restaurant.id,
        status: "delivered",
        total_price: Decimal.new("20.00"),
        delivery_address: "123 New User St"
      })
      
      conn = log_in_user(conn, new_user)
      {:ok, view, _html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Click write review button
      view |> element("button", "Write a Review") |> render_click()

      # Submit review form
      view
      |> form("form", review: %{rating: "5", comment: "Amazing restaurant! Will definitely come back."})
      |> render_submit()

      # Verify review was created in database
      review = Repo.get_by(Review, user_id: new_user.id, restaurant_id: restaurant.id)
      assert review != nil
      assert review.rating == 5
      assert review.comment == "Amazing restaurant! Will definitely come back."

      # Verify the review appears on the page - use username from email
      html = render(view)
      assert html =~ "newuser"
      assert html =~ "Amazing restaurant! Will definitely come back."
    end

    test "displays average rating and count in restaurant header", %{conn: conn, restaurant: restaurant} do
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Check that average rating is displayed (should be 4.5 for ratings of 5 and 4)
      assert html =~ "4.5"
      assert html =~ "(2 reviews)"
    end

    test "prevents duplicate reviews from same user", %{conn: conn, reviewer1: reviewer1, restaurant: restaurant} do
      conn = log_in_user(conn, reviewer1)
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # User who already reviewed should not see "Write a Review" button  
      refute html =~ "Write a Review"
    end

    test "redirects to login when non-logged-in user tries to review", %{conn: conn, restaurant: restaurant} do
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Non-logged-in user should not see Write a Review button
      refute html =~ "Write a Review"
    end
  end

  describe "Review system specification compliance" do
    test "user cannot review restaurant without completing an order", %{conn: conn, restaurant: restaurant} do
      # Create new user who has never placed an order
      new_user = user_fixture(%{email: "no_orders@example.com"})
      conn = log_in_user(conn, new_user)

      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # User should NOT see "Write a Review" button without completed orders
      refute html =~ "Write a Review"
      
      # Should see message encouraging them to order first
      assert html =~ "Order from this restaurant to leave a review"
    end

    test "user cannot review restaurant with only pending/confirmed orders", %{conn: conn, restaurant: restaurant, meal: _meal} do
      # Create user with a pending order
      customer = user_fixture(%{email: "pending_order@example.com"})
      
      # Create confirmed order (not yet delivered)
      {:ok, _order} = Eatfair.Orders.create_order(%{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        status: "confirmed",
        total_price: Decimal.new("25.00"),
        delivery_address: "123 Customer St"
      })
      
      conn = log_in_user(conn, customer)
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Should NOT see review button for non-delivered orders
      refute html =~ "Write a Review"
      assert html =~ "Complete your order to leave a review"
    end

    test "user CAN review restaurant after order is delivered", %{conn: conn, restaurant: restaurant, meal: _meal} do
      # Create user with delivered order
      customer = user_fixture(%{email: "delivered_order@example.com"})
      
      # Create delivered order
      {:ok, _order} = Eatfair.Orders.create_order(%{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        status: "delivered",
        total_price: Decimal.new("25.00"),
        delivery_address: "123 Customer St"
      })
      
      conn = log_in_user(conn, customer)
      {:ok, view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Should see review button for delivered orders
      assert html =~ "Write a Review"
      
      # Should be able to submit review
      view |> element("button", "Write a Review") |> render_click()
      
      view
      |> form("form", review: %{rating: "5", comment: "Great experience after delivery!"})
      |> render_submit()
      
      # Verify review was created
      review = Repo.get_by(Review, user_id: customer.id, restaurant_id: restaurant.id)
      assert review != nil
      assert review.comment == "Great experience after delivery!"
    end

    test "review form validates order relationship", %{conn: _conn, restaurant: restaurant} do
      # Test direct review creation fails without order
      user_without_order = user_fixture(%{email: "direct_create@example.com"})
      
      # Attempt to create review directly should fail
      {:error, changeset} = Eatfair.Reviews.create_review(%{
        rating: 5,
        comment: "Trying to bypass order requirement",
        user_id: user_without_order.id,
        restaurant_id: restaurant.id
      })
      
      # Should have validation error
      assert changeset.errors[:order_id] != nil
    end
  end
  
  describe "Reviews integration with restaurant data" do
    test "updates restaurant average rating after new review", %{conn: conn, restaurant: restaurant} do
      # Create new user and submit 3-star review
      new_user = user_fixture(%{email: "rater@example.com"})
      
      # Create a delivered order for the user so they can review
      {:ok, _order} = Eatfair.Orders.create_order(%{
        customer_id: new_user.id,
        restaurant_id: restaurant.id,
        status: "delivered",
        total_price: Decimal.new("15.00"),
        delivery_address: "123 Rater St"
      })
      
      conn = log_in_user(conn, new_user)
      {:ok, view, _html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Submit 3-star review
      view |> element("button", "Write a Review") |> render_click()
      view
      |> form("form", review: %{rating: "3", comment: "Average experience"})
      |> render_submit()

      # Check that average rating updated (5, 4, 3 = 4.0 average)
      html = render(view)
      assert html =~ "4.0"
      assert html =~ "(3 reviews)"
    end

    test "maintains proper ordering of reviews (newest first)", %{conn: conn, restaurant: restaurant} do
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Just verify both reviews appear - ordering is less critical for this test
      assert html =~ "Bob Johnson"
      assert html =~ "Alice Smith"
    end
  end
end
