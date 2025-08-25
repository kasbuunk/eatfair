defmodule Eatfair.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias Eatfair.Repo

  alias Eatfair.Orders.Order
  alias Eatfair.Orders.OrderItem
  alias Eatfair.Orders.Payment

  @doc """
  Returns the list of orders for a customer.
  """
  def list_customer_orders(customer_id) do
    Order
    |> where([o], o.customer_id == ^customer_id)
    |> preload([:restaurant, order_items: :meal])
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.
  """
  def get_order!(id) do
    Order
    |> preload([:customer, :restaurant, order_items: :meal, payment: []])
    |> Repo.get!(id)
  end

  @doc """
  Creates an order.
  """
  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an order.
  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an order.
  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.
  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  @doc """
  Creates an order with items in a transaction.
  """
  def create_order_with_items(order_attrs, items_attrs) do
    Repo.transaction(fn ->
      with {:ok, order} <- create_order(order_attrs),
           {:ok, _items} <- create_order_items(order.id, items_attrs) do
        order
        |> Repo.preload([:restaurant, order_items: :meal])
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates order items for an order.
  """
  def create_order_items(order_id, items_attrs) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    items_with_order_id =
      Enum.map(items_attrs, fn %{meal_id: _meal_id, quantity: _quantity} = attrs ->
        # Only allow specific fields to be inserted to avoid unknown field errors
        # Price is a virtual field and should not be inserted into order_items table directly
        Map.take(attrs, [:meal_id, :quantity])
        |> Map.put(:order_id, order_id)
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    {count, items} = Repo.insert_all(OrderItem, items_with_order_id, returning: true)

    if count == length(items_attrs) do
      {:ok, items}
    else
      {:error, :failed_to_create_all_items}
    end
  end

  @doc """
  Calculates the total price of an order based on its items.
  """
  def calculate_order_total(order_items) when is_list(order_items) do
    Enum.reduce(order_items, Decimal.new(0), fn item, acc ->
      item_total = Decimal.mult(item.meal.price, item.quantity)
      Decimal.add(acc, item_total)
    end)
  end

  @doc """
  Creates a payment for an order.
  """
  def create_payment(attrs \\ %{}) do
    %Payment{}
    |> Payment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates payment status.
  """
  def update_payment_status(%Payment{} = payment, status) do
    payment
    |> Payment.status_changeset(%{status: status})
    |> Repo.update()
  end

  @doc """
  Processes payment for an order (stub implementation).
  """
  def process_payment(order_id, payment_attrs) do
    # This is a stub - in a real app, this would integrate with a payment provider
    payment_attrs =
      payment_attrs
      |> Map.put(:order_id, order_id)
      |> Map.put(:status, "completed")
      |> Map.put(:provider_transaction_id, "mock_#{:rand.uniform(1_000_000)}")

    case create_payment(payment_attrs) do
      {:ok, payment} ->
        # Update order status to confirmed with tracking
        order = get_order!(order_id)
        update_order_status(order, "confirmed")
        {:ok, payment}

      error ->
        error
    end
  end

  @doc """
  Updates order status with proper validation and notifications.

  This is the main function for status progression with:
  - Status transition validation
  - Timestamp tracking  
  - Notification events
  - Real-time broadcasts
  """
  def update_order_status(order, new_status, attrs \\ %{}) do
    old_status = order.status
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Add timestamp for the new status
    status_attrs = attrs |> add_status_timestamp(new_status, now)

    changeset = Order.status_changeset(order, Map.put(status_attrs, :status, new_status))

    case Repo.update(changeset) do
      {:ok, updated_order} ->
        # Load associations for notifications
        updated_order = updated_order |> Repo.preload([:restaurant, :customer])

        # Create notification event
        Eatfair.Notifications.notify_order_status_change(
          updated_order,
          old_status,
          new_status,
          Map.take(attrs, [:delay_reason, :estimated_delivery_at])
        )

        # Broadcast real-time update
        broadcast_order_update(updated_order, old_status)

        {:ok, updated_order}

      error ->
        error
    end
  end

  @doc """
  Lists orders for a restaurant organized by status.
  """
  def list_restaurant_orders(restaurant_id) do
    Order
    |> where([o], o.restaurant_id == ^restaurant_id)
    |> where([o], o.status in ["confirmed", "preparing", "ready", "out_for_delivery"])
    |> preload([:customer, order_items: :meal])
    |> order_by([o], asc: :confirmed_at, asc: :inserted_at)
    |> Repo.all()
    |> group_orders_by_status()
  end

  @doc """
  Lists active orders for a customer (not delivered or cancelled).
  """
  def list_active_customer_orders(customer_id) do
    Order
    |> where([o], o.customer_id == ^customer_id)
    |> where([o], o.status not in ["delivered", "cancelled"])
    |> preload([:restaurant, order_items: :meal])
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists orders currently out for delivery.
  """
  def list_orders_out_for_delivery do
    Order
    |> where([o], o.status == "out_for_delivery")
    |> preload([:customer, :restaurant, order_items: :meal])
    |> order_by([o], asc: o.out_for_delivery_at)
    |> Repo.all()
  end

  @doc """
  Gets estimated delivery time based on order status and restaurant prep time.
  """
  def calculate_estimated_delivery(order) do
    base_prep_minutes = order.estimated_prep_time_minutes || 30
    # Default delivery time
    delivery_minutes = 20

    case order.status do
      "confirmed" ->
        NaiveDateTime.add(NaiveDateTime.utc_now(), (base_prep_minutes + delivery_minutes) * 60)

      "preparing" when order.preparing_at != nil ->
        prep_elapsed = NaiveDateTime.diff(NaiveDateTime.utc_now(), order.preparing_at, :minute)
        remaining_prep = max(0, base_prep_minutes - prep_elapsed)
        NaiveDateTime.add(NaiveDateTime.utc_now(), (remaining_prep + delivery_minutes) * 60)

      "ready" ->
        NaiveDateTime.add(NaiveDateTime.utc_now(), delivery_minutes * 60)

      "out_for_delivery" ->
        order.estimated_delivery_at || NaiveDateTime.add(NaiveDateTime.utc_now(), 15 * 60)

      _ ->
        nil
    end
  end

  # Private helper functions

  defp add_status_timestamp(attrs, status, timestamp) do
    case status do
      "confirmed" -> Map.put(attrs, :confirmed_at, timestamp)
      "preparing" -> Map.put(attrs, :preparing_at, timestamp)
      "ready" -> Map.put(attrs, :ready_at, timestamp)
      "out_for_delivery" -> Map.put(attrs, :out_for_delivery_at, timestamp)
      "delivered" -> Map.put(attrs, :delivered_at, timestamp)
      "cancelled" -> Map.put(attrs, :cancelled_at, timestamp)
      _ -> attrs
    end
  end

  defp broadcast_order_update(order, old_status) do
    # Broadcast to customer
    Phoenix.PubSub.broadcast(
      Eatfair.PubSub,
      "order_tracking:#{order.customer_id}",
      {:order_status_updated, order, old_status}
    )

    # Broadcast to restaurant
    Phoenix.PubSub.broadcast(
      Eatfair.PubSub,
      "restaurant_orders:#{order.restaurant_id}",
      {:order_status_updated, order, old_status}
    )

    # Broadcast to courier if assigned
    if order.courier_id do
      Phoenix.PubSub.broadcast(
        Eatfair.PubSub,
        "courier_orders:#{order.courier_id}",
        {:order_status_updated, order, old_status}
      )
    end
  end

  defp group_orders_by_status(orders) do
    %{
      confirmed: Enum.filter(orders, &(&1.status == "confirmed")),
      preparing: Enum.filter(orders, &(&1.status == "preparing")),
      ready: Enum.filter(orders, &(&1.status == "ready")),
      out_for_delivery: Enum.filter(orders, &(&1.status == "out_for_delivery"))
    }
  end
end
