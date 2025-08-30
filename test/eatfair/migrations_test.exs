defmodule Eatfair.MigrationsTest do
  use Eatfair.DataCase

  alias Eatfair.{Repo, Orders, Reviews}
  alias Eatfair.Reviews.ReviewImage

  describe "donation fields migration" do
    test "orders table has donation_amount field with correct default" do
      # This test validates the migration adds donation_amount field
      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant_fixture().id,
        customer_email: "test@example.com",
        customer_phone: "123456789",
        delivery_address: "Test Address 123",
        total_price: Decimal.new("25.50")
      })

      # Should have default donation_amount of 0.00
      assert order.donation_amount == Decimal.new("0.00")
      assert order.donation_currency == "EUR"
    end

    test "can store positive donation amounts" do
      restaurant = restaurant_fixture()
      
      # Test that we can store donation amounts > 0
      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "donor@example.com", 
        customer_phone: "123456789",
        delivery_address: "Donor Address 123",
        total_price: Decimal.new("30.00"),
        donation_amount: Decimal.new("5.00")
      })

      assert order.donation_amount == Decimal.new("5.00")
    end

    test "donation_amount has proper decimal precision" do
      restaurant = restaurant_fixture()
      
      # Test decimal precision handling
      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "precision@example.com",
        customer_phone: "123456789", 
        delivery_address: "Precision Address 123",
        total_price: Decimal.new("15.75"),
        donation_amount: Decimal.new("2.53")
      })

      assert order.donation_amount == Decimal.new("2.53")
    end
  end

  describe "review images table migration" do
    test "review_images table exists with correct fields" do
      # Should be able to query ReviewImage now that schema exists
      images = Repo.all(ReviewImage)
      assert is_list(images)
      assert images == []
    end

    test "can create review image with required fields" do
      # Create test data
      restaurant = restaurant_fixture()
      customer = user_fixture()
      
      {:ok, order} = Orders.create_order(%{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        status: "delivered",
        total_price: Decimal.new("20.00"),
        delivery_address: "Review Test Address"
      })

      {:ok, review} = Reviews.create_review(%{
        rating: 5,
        comment: "Great food!",
        user_id: customer.id,
        restaurant_id: restaurant.id,
        order_id: order.id
      })

      # Should be able to create ReviewImage changeset now
      changeset = ReviewImage.changeset(%ReviewImage{}, %{
        review_id: review.id,
        image_path: "/uploads/reviews/test.jpg",
        position: 1,
        file_size: 150_000,
        mime_type: "image/jpeg"
      })
      
      assert changeset.valid?
      
      # Should be able to insert the review image
      {:ok, review_image} = Repo.insert(changeset)
      assert review_image.review_id == review.id
      assert review_image.image_path == "/uploads/reviews/test.jpg"
      assert review_image.position == 1
    end

    test "review images have unique position constraint per review" do
      # Create test data
      restaurant = restaurant_fixture()
      customer = user_fixture()
      
      {:ok, order} = Orders.create_order(%{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        status: "delivered",
        total_price: Decimal.new("20.00"),
        delivery_address: "Constraint Test Address"
      })

      {:ok, review} = Reviews.create_review(%{
        rating: 4,
        comment: "Testing constraints!",
        user_id: customer.id,
        restaurant_id: restaurant.id,
        order_id: order.id
      })
      
      # First image at position 1
      changeset1 = ReviewImage.changeset(%ReviewImage{}, %{
        review_id: review.id,
        image_path: "/uploads/reviews/first.jpg",
        position: 1,
        file_size: 100_000,
        mime_type: "image/jpeg"
      })
      
      {:ok, _image1} = Repo.insert(changeset1)
      
      # Second image at same position should fail
      changeset2 = ReviewImage.changeset(%ReviewImage{}, %{
        review_id: review.id,
        image_path: "/uploads/reviews/second.jpg",
        position: 1,  # Same position!
        file_size: 120_000,
        mime_type: "image/png"
      })
      
      assert {:error, changeset} = Repo.insert(changeset2)
      assert "has already been taken" in errors_on(changeset).review_id
    end
  end

  # Helper functions for creating test fixtures
  defp restaurant_fixture do
    %{id: restaurant_id} = Eatfair.RestaurantsFixtures.restaurant_fixture()
    Eatfair.Restaurants.get_restaurant!(restaurant_id)
  end

  defp user_fixture do
    Eatfair.AccountsFixtures.user_fixture()
  end
end
