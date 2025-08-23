defmodule Eatfair.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Orders.Order
  alias Eatfair.Restaurants.Meal

  schema "order_items" do
    field :quantity, :integer
    field :customization_options, {:array, :integer}, default: []

    belongs_to :order, Order
    belongs_to :meal, Meal

    timestamps()
  end

  @doc false
  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity, :customization_options, :order_id, :meal_id])
    |> validate_required([:quantity, :order_id, :meal_id])
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:meal_id)
  end
end
