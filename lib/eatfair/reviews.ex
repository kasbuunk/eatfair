defmodule Eatfair.Reviews do
  @moduledoc """
  The Reviews context.
  """

  import Ecto.Query, warn: false
  alias Eatfair.Repo

  alias Eatfair.Reviews.Review

  @doc """
  Returns the list of reviews for a restaurant.
  """
  def list_reviews_for_restaurant(restaurant_id) do
    from(r in Review,
      where: r.restaurant_id == ^restaurant_id,
      order_by: [desc: r.inserted_at],
      preload: [:user, :review_images]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single review.
  """
  def get_review!(id), do: Repo.get!(Review, id)

  @doc """
  Creates a review.
  """
  def create_review(attrs \\ %{}) do
    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a review with associated images.
  """
  def create_review_with_images(attrs, image_uploads) do
    Repo.transaction(fn ->
      case create_review(attrs) do
        {:ok, review} ->
          # Create image records for each uploaded image
          image_results =
            Enum.with_index(image_uploads, 1)
            |> Enum.map(fn {image_data, position} ->
              case image_data do
                {:ok, image_attrs} ->
                  %Eatfair.Reviews.ReviewImage{}
                  |> Eatfair.Reviews.ReviewImage.changeset(
                    Map.merge(image_attrs, %{
                      review_id: review.id,
                      position: position
                    })
                  )
                  |> Repo.insert()

                {:error, _reason} = error ->
                  error
              end
            end)

          # Check if any image creation failed
          case Enum.find(image_results, &match?({:error, _}, &1)) do
            {:error, _changeset} = error ->
              Repo.rollback(error)

            nil ->
              # All images created successfully
              review
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates a review.
  """
  def update_review(%Review{} = review, attrs) do
    review
    |> Review.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a review.
  """
  def delete_review(%Review{} = review) do
    Repo.delete(review)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking review changes.
  """
  def change_review(%Review{} = review, attrs \\ %{}) do
    Review.changeset(review, attrs)
  end

  @doc """
  Calculates the average rating for a restaurant.
  """
  def get_average_rating(restaurant_id) do
    from(r in Review,
      where: r.restaurant_id == ^restaurant_id,
      select: avg(r.rating)
    )
    |> Repo.one()
  end

  @doc """
  Gets the review count for a restaurant.
  """
  def get_review_count(restaurant_id) do
    from(r in Review, where: r.restaurant_id == ^restaurant_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Checks if a user has already reviewed a restaurant.
  """
  def user_has_reviewed?(user_id, restaurant_id) do
    from(r in Review, where: r.user_id == ^user_id and r.restaurant_id == ^restaurant_id)
    |> Repo.exists?()
  end

  @doc """
  Checks if a user can review a restaurant based on delivered orders.
  Prevents restaurant owners from reviewing their own restaurants.
  """
  def user_can_review?(user_id, restaurant_id) do
    import Ecto.Query
    alias Eatfair.Orders.Order
    alias Eatfair.Restaurants.Restaurant

    # First check: User cannot review their own restaurant
    is_restaurant_owner =
      from(r in Restaurant,
        where: r.id == ^restaurant_id and r.owner_id == ^user_id
      )
      |> Repo.exists?()

    # If user owns the restaurant, they cannot review it
    if is_restaurant_owner do
      false
    else
      # User can review if they have at least one delivered order from this restaurant
      # and haven't already reviewed it
      delivered_order_exists =
        from(o in Order,
          where:
            o.customer_id == ^user_id and
              o.restaurant_id == ^restaurant_id and
              o.status == "delivered"
        )
        |> Repo.exists?()

      delivered_order_exists and not user_has_reviewed?(user_id, restaurant_id)
    end
  end

  @doc """
  Gets a delivered order that can be used for creating a review.
  Returns nil if no eligible order exists.
  """
  def get_reviewable_order(user_id, restaurant_id) do
    import Ecto.Query
    alias Eatfair.Orders.Order

    from(o in Order,
      where:
        o.customer_id == ^user_id and
          o.restaurant_id == ^restaurant_id and
          o.status == "delivered",
      order_by: [desc: o.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end
end
