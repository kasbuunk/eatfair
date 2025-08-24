defmodule Eatfair.Reviews.Review do
  use Ecto.Schema
  import Ecto.Changeset
  
  alias Eatfair.Accounts.User
  alias Eatfair.Restaurants.Restaurant

  schema "reviews" do
    field :rating, :integer
    field :comment, :string
    
    belongs_to :user, User
    belongs_to :restaurant, Restaurant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [:rating, :comment, :user_id, :restaurant_id])
    |> validate_required([:rating, :user_id, :restaurant_id])
    |> validate_inclusion(:rating, 1..5)
    |> validate_length(:comment, max: 1000)
    |> unique_constraint([:restaurant_id, :user_id])
  end
end
