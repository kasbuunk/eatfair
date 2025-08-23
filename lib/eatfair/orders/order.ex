defmodule Eatfair.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User
  alias Eatfair.Restaurants.Restaurant
  alias Eatfair.Orders.OrderItem
  alias Eatfair.Orders.Payment

  @valid_statuses ["pending", "confirmed", "preparing", "ready", "delivered", "cancelled"]

  schema "orders" do
    field :status, :string, default: "pending"
    field :total_price, :decimal
    field :delivery_address, :string
    field :delivery_notes, :string

    belongs_to :customer, User
    belongs_to :restaurant, Restaurant
    has_many :order_items, OrderItem
    has_one :payment, Payment

    timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:status, :total_price, :delivery_address, :delivery_notes, :customer_id, :restaurant_id])
    |> validate_required([:customer_id, :restaurant_id])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:total_price, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:restaurant_id)
  end
end
