defmodule Eatfair.Orders.DeliveryBatch do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User
  alias Eatfair.Restaurants.Restaurant
  alias Eatfair.Orders.Order

  @valid_statuses [
    # Being created by restaurant owner
    "draft",
    # Proposed to courier, awaiting acceptance
    "proposed",
    # Courier accepted
    "accepted",
    # Final schedule confirmed
    "scheduled",
    # Courier is picking up/delivering
    "in_progress",
    # All orders delivered
    "completed",
    # Batch cancelled
    "cancelled"
  ]

  schema "delivery_batches" do
    field :name, :string
    field :status, :string, default: "draft"
    field :scheduled_pickup_time, :naive_datetime
    field :estimated_delivery_time, :naive_datetime
    field :notes, :string
    
    # Auto-assignment fields
    field :auto_assigned, :boolean, default: false

    belongs_to :courier, User
    belongs_to :suggested_courier, User
    belongs_to :restaurant, Restaurant
    has_many :orders, Order, foreign_key: :delivery_batch_id

    timestamps(type: :utc_datetime)
  end

  def valid_statuses, do: @valid_statuses

  @doc false
  def changeset(delivery_batch, attrs) do
    delivery_batch
    |> cast(attrs, [
      :name,
      :status,
      :scheduled_pickup_time,
      :estimated_delivery_time,
      :notes,
      :courier_id,
      :restaurant_id,
      :auto_assigned,
      :suggested_courier_id
    ])
    |> validate_required([:name, :restaurant_id])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:notes, max: 1000)
    |> validate_future_pickup_time()
    |> foreign_key_constraint(:courier_id)
    |> foreign_key_constraint(:restaurant_id)
  end

  defp validate_future_pickup_time(changeset) do
    case get_change(changeset, :scheduled_pickup_time) do
      nil ->
        changeset

      pickup_time ->
        if NaiveDateTime.compare(pickup_time, NaiveDateTime.utc_now()) != :gt do
          add_error(changeset, :scheduled_pickup_time, "must be in the future")
        else
          changeset
        end
    end
  end
end
