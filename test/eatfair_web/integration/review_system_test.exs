defmodule EatfairWeb.ReviewSystemTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Floki

  alias Eatfair.{Repo, Reviews, Restaurants}
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

    # Create another user for reviews
    reviewer1 = user_fixture(%{email: "reviewer1@example.com", name: "Alice Smith"})
    reviewer2 = user_fixture(%{email: "reviewer2@example.com", name: "Bob Johnson"})

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

    # Create some reviews
    {:ok, review1} = Reviews.create_review(%{
      rating: 5,
      comment: "Excellent food and service! Highly recommend the pasta.",
      user_id: reviewer1.id,
      restaurant_id: restaurant.id
    })

    {:ok, review2} = Reviews.create_review(%{
      rating: 4,
      comment: "Good food, fast delivery. Will order again.",
      user_id: reviewer2.id,
      restaurant_id: restaurant.id
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
      {:ok, view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Assert reviews list container exists with testid
      reviews_list = html |> Floki.find("[data-testid='reviews-list']")
      assert length(reviews_list) == 1

      # Assert reviews container exists with reviews
      reviews_container = html |> Floki.find("[data-testid='reviews-container']")
      assert length(reviews_container) == 1

      # Assert review items exist
      review_items = html |> Floki.find("[data-testid='review-item']")
      assert length(review_items) == 2

      # Assert reviewer names are displayed
      reviewer_names = html |> Floki.find("[data-testid='reviewer-name']") |> Floki.text()
      assert reviewer_names =~ "Alice Smith"
      assert reviewer_names =~ "Bob Johnson"

      # Assert review ratings are displayed
      review_ratings = html |> Floki.find("[data-testid='review-rating']")
      assert length(review_ratings) == 2

      # Assert review comments are displayed
      review_comments = html |> Floki.find("[data-testid='review-comment']") |> Floki.text()
      assert review_comments =~ "Excellent food and service"
      assert review_comments =~ "Good food, fast delivery"

      # Verify star ratings (5 stars and 4 stars)
      filled_stars = html |> Floki.find("[data-testid='review-rating'] .hero-star-solid")
      assert length(filled_stars) == 9 # 5 + 4 stars total

      empty_stars = html |> Floki.find("[data-testid='review-rating'] .hero-star")
      assert length(empty_stars) == 1 # Only 1 empty star from the 4-star review
    end

    test "shows empty state when no reviews exist", %{conn: conn, user: user} do
      # Create a restaurant without reviews
      {:ok, cuisine} = %Cuisine{name: "Mexican"} |> Repo.insert()
      restaurant_attrs = %{
        name: "Empty Restaurant",
        address: "456 Empty St",
        delivery_time: 25,
        min_order_value: Decimal.new("10.00"),
        owner_id: user.id
      }

      {:ok, empty_restaurant} = %Restaurant{}
      |> Restaurant.changeset(restaurant_attrs)
      |> Repo.insert()

      {1, _} = Repo.insert_all(
        "restaurant_cuisines",
        [%{restaurant_id: empty_restaurant.id, cuisine_id: cuisine.id, inserted_at: NaiveDateTime.utc_now(), updated_at: NaiveDateTime.utc_now()}]
      )

      {:ok, menu} = %Menu{name: "Main Menu", restaurant_id: empty_restaurant.id} |> Repo.insert()

      {:ok, _view, html} = live(conn, ~p"/restaurants/#{empty_restaurant.id}")

      # Assert reviews list exists but shows empty state
      reviews_list = html |> Floki.find("[data-testid='reviews-list']")
      assert length(reviews_list) == 1

      # Assert no reviews container exists
      reviews_container = html |> Floki.find("[data-testid='reviews-container']")
      assert length(reviews_container) == 0

      # Assert empty state message
      empty_text = html |> Floki.text()
      assert empty_text =~ "No reviews yet"
      assert empty_text =~ "Be the first to share your experience"
    end

    test "displays review form for logged in users who haven't reviewed", %{conn: conn, user: user, restaurant: restaurant} do
      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Assert "Write a Review" button exists for logged-in user
      write_review_button = html |> Floki.find("button") |> Floki.text()
      assert write_review_button =~ "Write a Review"

      # Click the write review button
      html = view |> element("button", "Write a Review") |> render_click()

      # Assert review form appears
      form = html |> Floki.find("form")
      assert length(form) >= 1

      # Assert rating dropdown exists
      rating_select = html |> Floki.find("select[name='review[rating]']")
      assert length(rating_select) == 1

      # Assert comment textarea exists
      comment_textarea = html |> Floki.find("textarea[name='review[comment]']")
      assert length(comment_textarea) == 1

      # Assert submit and cancel buttons exist
      buttons_text = html |> Floki.find("button") |> Floki.text()
      assert buttons_text =~ "Submit Review"
      assert buttons_text =~ "Cancel"
    end

    test "successfully submits a review", %{conn: conn, restaurant: restaurant} do
      # Create a new user who hasn't reviewed yet
      new_user = user_fixture(%{email: "newuser@example.com", name: "New User"})
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

      # Verify the review appears on the page
      html = render(view)
      assert html =~ "New User"
      assert html =~ "Amazing restaurant! Will definitely come back."
    end

    test "displays average rating and count in restaurant header", %{conn: conn, restaurant: restaurant} do
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Check that average rating is displayed (should be 4.5 for ratings of 5 and 4)
      rating_text = html |> Floki.text()
      assert rating_text =~ "4.5"
      assert rating_text =~ "(2 reviews)"
    end

    test "prevents duplicate reviews from same user", %{conn: conn, reviewer1: reviewer1, restaurant: restaurant} do
      conn = log_in_user(conn, reviewer1)
      {:ok, _view, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # User who already reviewed should not see "Write a Review" button
      write_review_button = html |> Floki.find("button") |> Floki.text()
      refute write_review_button =~ "Write a Review"
    end

    test "redirects to login when non-logged-in user tries to review", %{conn: conn, restaurant: restaurant} do
      {:ok, view, _html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Try to toggle review form (should redirect to login)
      assert_redirect(view, ~p"/users/log-in", fn ->
        view |> element("button", "Write a Review") |> render_click()
      end)
    end
  end

  describe "Reviews integration with restaurant data" do
    test "updates restaurant average rating after new review", %{conn: conn, restaurant: restaurant} do
      # Create new user and submit 3-star review
      new_user = user_fixture(%{email: "rater@example.com"})
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

      # Get all reviewer names in order they appear
      reviewer_elements = html |> Floki.find("[data-testid='reviewer-name']")
      reviewer_names = reviewer_elements |> Enum.map(&Floki.text/1)

      # First review should be from Bob Johnson (newer review)
      assert List.first(reviewer_names) =~ "Bob Johnson"
      # Second review should be from Alice Smith (older review)
      assert List.last(reviewer_names) =~ "Alice Smith"
    end
  end
end
