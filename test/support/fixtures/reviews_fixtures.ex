defmodule Eatfair.ReviewsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  review-related entities via the `Eatfair.Reviews` context.
  """

  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures
  import Eatfair.OrdersFixtures

  alias Eatfair.Reviews

  @doc """
  Generate a review with a delivered order.
  """
  def review_fixture(attrs \\ %{}) do
    user = (attrs[:user_id] && Eatfair.Accounts.get_user!(attrs[:user_id])) || user_fixture()

    restaurant =
      (attrs[:restaurant_id] && Eatfair.Restaurants.get_restaurant!(attrs[:restaurant_id])) ||
        restaurant_fixture()

    # Create a delivered order if none provided
    order =
      if attrs[:order_id] do
        Eatfair.Orders.get_order!(attrs[:order_id])
      else
        order_fixture(%{
          customer_id: user.id,
          restaurant_id: restaurant.id,
          status: "delivered"
        })
      end

    attrs =
      %{
        rating: 5,
        comment: "Great food and service!",
        user_id: user.id,
        restaurant_id: restaurant.id,
        order_id: order.id
      }
      |> Map.merge(Enum.into(attrs, %{}))

    {:ok, review} = Reviews.create_review(attrs)
    review
  end

  @doc """
  Generate a review image.
  """
  def review_image_fixture(attrs \\ %{}) do
    review =
      if attrs[:review_id] do
        Reviews.get_review!(attrs[:review_id])
      else
        review_fixture()
      end

    attrs =
      %{
        review_id: review.id,
        image_path: "/uploads/reviews/test_#{System.unique_integer([:positive])}.jpg",
        compressed_path:
          "/uploads/reviews/test_#{System.unique_integer([:positive])}_compressed.jpg",
        position: 1,
        file_size: 150_000,
        mime_type: "image/jpeg"
      }
      |> Map.merge(Enum.into(attrs, %{}))

    {:ok, review_image} =
      %Eatfair.Reviews.ReviewImage{}
      |> Eatfair.Reviews.ReviewImage.changeset(attrs)
      |> Eatfair.Repo.insert()

    review_image
  end

  @doc """
  Generate multiple review images for a review.
  """
  def review_images_fixture(review_id, count \\ 3) do
    Enum.map(1..count, fn position ->
      review_image_fixture(%{
        review_id: review_id,
        position: position,
        image_path: "/uploads/reviews/test_#{position}_#{System.unique_integer([:positive])}.jpg"
      })
    end)
  end
end
