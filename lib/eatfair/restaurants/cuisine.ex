defmodule Eatfair.Restaurants.Cuisine do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Restaurants.Restaurant

  schema "cuisines" do
    field :name, :string

    many_to_many :restaurants, Restaurant, join_through: "restaurant_cuisines"

    timestamps()
  end

  @doc false
  def changeset(cuisine, attrs) do
    cuisine
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 50)
    |> unique_constraint(:name)
  end
end
