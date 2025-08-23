defmodule Eatfair.Restaurants.Restaurant do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User
  alias Eatfair.Restaurants.Cuisine
  alias Eatfair.Restaurants.Menu

  schema "restaurants" do
    field :name, :string
    field :address, :string
    field :delivery_time, :integer
    field :min_order_value, :decimal
    field :is_open, :boolean, default: true
    field :rating, :decimal
    field :image_url, :string

    belongs_to :owner, User
    many_to_many :cuisines, Cuisine, join_through: "restaurant_cuisines"
    has_many :menus, Menu

    timestamps()
  end

  @doc false
  def changeset(restaurant, attrs) do
    restaurant
    |> cast(attrs, [:name, :address, :delivery_time, :min_order_value, :is_open, :rating, :image_url, :owner_id])
    |> validate_required([:name, :owner_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_number(:delivery_time, greater_than: 0)
    |> validate_number(:min_order_value, greater_than_or_equal_to: 0)
    |> validate_number(:rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> foreign_key_constraint(:owner_id)
    |> unique_constraint(:owner_id)
  end
end
