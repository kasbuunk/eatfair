defmodule Eatfair.Restaurants.Menu do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Restaurants.Restaurant
  alias Eatfair.Restaurants.Meal

  schema "menus" do
    field :name, :string

    belongs_to :restaurant, Restaurant
    has_many :meals, Meal

    timestamps()
  end

  @doc false
  def changeset(menu, attrs) do
    menu
    |> cast(attrs, [:name, :restaurant_id])
    |> validate_required([:name, :restaurant_id])
    |> validate_length(:name, min: 2, max: 100)
    |> foreign_key_constraint(:restaurant_id)
  end
end
