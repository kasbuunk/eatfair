defmodule Eatfair.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User
  alias Eatfair.Restaurants.Restaurant
  alias Eatfair.Orders.OrderItem
  alias Eatfair.Orders.Payment

  @valid_statuses [
    "pending",
    "confirmed",
    "preparing",
    "ready",
    "out_for_delivery",
    "delivered",
    "cancelled"
  ]

  schema "orders" do
    field :status, :string, default: "pending"
    field :total_price, :decimal
    field :delivery_address, :string
    field :delivery_notes, :string

    # Status transition timestamps
    field :confirmed_at, :naive_datetime
    field :preparing_at, :naive_datetime
    field :ready_at, :naive_datetime
    field :out_for_delivery_at, :naive_datetime
    field :delivered_at, :naive_datetime
    field :cancelled_at, :naive_datetime

    # Tracking details
    field :estimated_delivery_at, :naive_datetime
    field :estimated_prep_time_minutes, :integer
    field :actual_prep_time_minutes, :integer

    # Special circumstances
    field :is_delayed, :boolean, default: false
    field :delay_reason, :string
    field :special_instructions, :string

    belongs_to :customer, User
    belongs_to :restaurant, Restaurant
    # For future courier assignment
    belongs_to :courier, User
    has_many :order_items, OrderItem
    has_one :payment, Payment

    timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :status,
      :total_price,
      :delivery_address,
      :delivery_notes,
      :customer_id,
      :restaurant_id,
      :courier_id,
      :confirmed_at,
      :preparing_at,
      :ready_at,
      :out_for_delivery_at,
      :delivered_at,
      :cancelled_at,
      :estimated_delivery_at,
      :estimated_prep_time_minutes,
      :actual_prep_time_minutes,
      :is_delayed,
      :delay_reason,
      :special_instructions
    ])
    |> validate_required([:customer_id, :restaurant_id, :delivery_address])
    |> validate_length(:delivery_address,
      min: 5,
      message: "Please provide a complete delivery address"
    )
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:total_price, greater_than_or_equal_to: 0)
    |> validate_number(:estimated_prep_time_minutes, greater_than: 0)
    |> validate_number(:actual_prep_time_minutes, greater_than: 0)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:restaurant_id)
    |> foreign_key_constraint(:courier_id)
  end

  @doc false
  def status_changeset(order, attrs) do
    order
    |> cast(attrs, [
      :status,
      :confirmed_at,
      :preparing_at,
      :ready_at,
      :out_for_delivery_at,
      :delivered_at,
      :cancelled_at,
      :is_delayed,
      :delay_reason,
      :actual_prep_time_minutes
    ])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_status_transition()
  end

  defp validate_status_transition(changeset) do
    case {get_field(changeset, :status), changeset.data.status} do
      {new_status, old_status} when new_status == old_status ->
        changeset

      # Can cancel from any status
      {"cancelled", _} ->
        changeset

      {"confirmed", "pending"} ->
        changeset

      {"preparing", "confirmed"} ->
        changeset

      {"ready", "preparing"} ->
        changeset

      {"out_for_delivery", "ready"} ->
        changeset

      {"delivered", "out_for_delivery"} ->
        changeset

      {new_status, old_status} ->
        add_error(changeset, :status, "cannot transition from #{old_status} to #{new_status}")
    end
  end
end
