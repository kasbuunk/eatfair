defmodule Eatfair.Restaurants.Restaurant do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User
  alias Eatfair.Restaurants.Cuisine
  alias Eatfair.Restaurants.Menu

  schema "restaurants" do
    field :name, :string
    field :address, :string
    field :description, :string
    field :avg_preparation_time, :integer, default: 30  # minutes
    field :delivery_radius_km, :integer, default: 5
    field :delivery_time_per_km, :integer, default: 3  # minutes per km
    field :min_order_value, :decimal, default: Decimal.new("15.00")
    field :is_open, :boolean, default: true
    field :rating, :decimal
    field :image_url, :string
    field :cuisine_types, {:array, :string}, default: []

    belongs_to :owner, User
    many_to_many :cuisines, Cuisine, join_through: "restaurant_cuisines"
    has_many :menus, Menu

    timestamps()
  end

  # Available cuisine options for simple selection
  @cuisine_options [
    "Local/European",
    "Asian/International"
  ]

  def cuisine_options, do: @cuisine_options

  @doc false
  def changeset(restaurant, attrs) do
    restaurant
    |> cast(attrs, [
      :name, :address, :description, :avg_preparation_time, 
      :delivery_radius_km, :delivery_time_per_km, :min_order_value, 
      :is_open, :rating, :image_url, :cuisine_types, :owner_id
    ])
    |> validate_required([:name, :address, :owner_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:address, min: 5, max: 200)
    |> validate_length(:description, max: 500)
    |> validate_number(:avg_preparation_time, greater_than: 0, less_than: 180)  # max 3 hours
    |> validate_number(:delivery_radius_km, greater_than: 0, less_than: 50)
    |> validate_number(:delivery_time_per_km, greater_than: 0, less_than: 15)
    |> validate_number(:min_order_value, greater_than_or_equal_to: 0)
    |> validate_number(:rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_cuisine_types()
    |> foreign_key_constraint(:owner_id)
    |> unique_constraint(:owner_id)
  end

  defp validate_cuisine_types(changeset) do
    validate_change(changeset, :cuisine_types, fn :cuisine_types, types ->
      case Enum.all?(types, &(&1 in @cuisine_options)) do
        true -> []
        false -> [cuisine_types: "contains invalid cuisine type"]
      end
    end)
  end
end
