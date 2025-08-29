defmodule Eatfair.Orders.OrderStatusEvent do
  @moduledoc """
  Schema for immutable order status tracking events.
  
  This table maintains a complete audit trail of all order status changes,
  with each status transition recorded as a new event rather than updating
  existing records. Current order status is determined by querying the most
  recent event for an order.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  alias Eatfair.Orders.Order
  alias Eatfair.Accounts.User

  @valid_statuses [
    "order_placed",
    "order_accepted", 
    "order_rejected",
    "cooking",
    "ready_for_courier",
    "in_transit",
    "delivered",
    "delivery_failed"
  ]
  
  @valid_actor_types ["customer", "restaurant", "courier", "system"]

  schema "order_status_events" do
    field :status, :string
    field :occurred_at, :utc_datetime
    field :actor_type, :string
    field :metadata, :map, default: %{}
    field :notes, :string
    
    belongs_to :order, Order
    belongs_to :actor, User
    
    timestamps()
  end

  @doc false
  def changeset(order_status_event, attrs) do
    order_status_event
    |> cast(attrs, [
      :order_id,
      :status, 
      :occurred_at,
      :actor_id,
      :actor_type,
      :metadata,
      :notes
    ])
    |> validate_required([:order_id, :status, :occurred_at, :actor_type])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_inclusion(:actor_type, @valid_actor_types)
    |> validate_occurred_at_not_future()
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:actor_id)
  end

  @doc """
  Creates a changeset for a new status event with default occurred_at to now.
  """
  def create_changeset(attrs) do
    attrs_with_defaults = 
      attrs
      |> Map.put_new(:occurred_at, DateTime.utc_now())
      |> Map.put_new(:metadata, %{})
    
    %__MODULE__{}
    |> changeset(attrs_with_defaults)
  end

  defp validate_occurred_at_not_future(changeset) do
    case get_field(changeset, :occurred_at) do
      nil -> changeset
      occurred_at ->
        if DateTime.compare(occurred_at, DateTime.utc_now()) == :gt do
          add_error(changeset, :occurred_at, "cannot be in the future")
        else
          changeset
        end
    end
  end
  
  @doc """
  Returns user-friendly status descriptions for display.
  """
  def status_description("order_placed"), do: "Your order is being sent to the restaurant"
  def status_description("order_accepted"), do: "Restaurant is preparing your order"  
  def status_description("order_rejected"), do: "Order could not be fulfilled"
  def status_description("cooking"), do: "Your food is being cooked"
  def status_description("ready_for_courier"), do: "Your order is ready and waiting for pickup"
  def status_description("in_transit"), do: "Your order is on the way"
  def status_description("delivered"), do: "Your order has been delivered!"
  def status_description("delivery_failed"), do: "Delivery encountered an issue"
  def status_description(_), do: "Status update"
  
  @doc """
  Returns whether this status represents a completed order journey.
  """
  def terminal_status?("delivered"), do: true
  def terminal_status?("order_rejected"), do: true  
  def terminal_status?("delivery_failed"), do: true
  def terminal_status?(_), do: false
  
  @doc """
  Returns the next expected statuses from the current status.
  """
  def next_statuses("order_placed"), do: ["order_accepted", "order_rejected"]
  def next_statuses("order_accepted"), do: ["cooking"]
  def next_statuses("cooking"), do: ["ready_for_courier"]
  def next_statuses("ready_for_courier"), do: ["in_transit"]
  def next_statuses("in_transit"), do: ["delivered", "delivery_failed"]
  def next_statuses(_terminal), do: []
end
