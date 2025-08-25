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
      preload: [:user]
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
  """
  def user_can_review?(user_id, restaurant_id) do
    import Ecto.Query
    alias Eatfair.Orders.Order

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
