defmodule Eatfair.Restaurants.Meal do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Restaurants.Menu

  schema "meals" do
    field :name, :string
    field :description, :string
    field :price, :decimal
    field :is_available, :boolean, default: true

    belongs_to :menu, Menu

    timestamps()
  end

  @doc false
  def changeset(meal, attrs) do
    meal
    |> cast(attrs, [:name, :description, :price, :is_available, :menu_id])
    |> validate_required([:name, :price, :menu_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_number(:price, greater_than: 0)
    |> foreign_key_constraint(:menu_id)
  end
end
