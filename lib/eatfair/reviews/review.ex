defmodule Eatfair.Reviews.Review do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User
  alias Eatfair.Restaurants.Restaurant
  alias Eatfair.Orders.Order

  schema "reviews" do
    field :rating, :integer
    field :comment, :string

    belongs_to :user, User
    belongs_to :restaurant, Restaurant
    belongs_to :order, Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [:rating, :comment, :user_id, :restaurant_id, :order_id])
    |> validate_required([:rating, :user_id, :restaurant_id, :order_id])
    |> validate_inclusion(:rating, 1..5)
    |> validate_length(:comment, max: 1000)
    |> unique_constraint([:restaurant_id, :user_id])
    |> foreign_key_constraint(:order_id)
    |> validate_order_belongs_to_user_and_restaurant()
  end

  defp validate_order_belongs_to_user_and_restaurant(changeset) do
    case get_change(changeset, :order_id) do
      nil ->
        changeset

      order_id ->
        user_id = get_change(changeset, :user_id)
        restaurant_id = get_change(changeset, :restaurant_id)

        if user_id && restaurant_id do
          validate_order_relationship(changeset, order_id, user_id, restaurant_id)
        else
          changeset
        end
    end
  end

  defp validate_order_relationship(changeset, order_id, user_id, restaurant_id) do
    import Ecto.Query

    # Check if order exists and belongs to user/restaurant with "delivered" status
    query =
      from(o in Order,
        where:
          o.id == ^order_id and
            o.customer_id == ^user_id and
            o.restaurant_id == ^restaurant_id and
            o.status == "delivered"
      )

    case Eatfair.Repo.exists?(query) do
      true ->
        changeset

      false ->
        add_error(
          changeset,
          :order_id,
          "must be a delivered order from this restaurant by this user"
        )
    end
  end
end
