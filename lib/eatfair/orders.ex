defmodule Eatfair.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias Eatfair.Repo

  alias Eatfair.Orders.Order
  alias Eatfair.Orders.OrderItem
  alias Eatfair.Orders.Payment
  alias Eatfair.Orders.OrderStatusEvent
  alias Eatfair.Orders.CourierLocationUpdate
  alias Eatfair.Orders.DeliveryBatch
  alias Eatfair.Refunds
  alias Eatfair.Notifications

  @doc """
  Counts orders based on optional filters for admin dashboard metrics.

  ## Options

    * `:status` - Count orders with specific status (can be atom or list of atoms)
    * `:date` - Count orders for specific date
    * `:since` - Count orders created since given date
    * `:customer` - Count orders for specific customer
    * `:restaurant` - Count orders for specific restaurant

  ## Examples

      iex> count_orders()
      150

      iex> count_orders(status: [:pending, :confirmed])
      25

      iex> count_orders(date: Date.utc_today())
      12

  """
  def count_orders(opts \\ []) do
    query =
      Order
      |> select([o], count(o.id))
      |> maybe_filter_order_status(opts[:status])
      |> maybe_filter_order_date(opts[:date])
      |> maybe_filter_order_since(opts[:since])
      |> maybe_filter_order_customer(opts[:customer])
      |> maybe_filter_order_restaurant(opts[:restaurant])

    Repo.one(query)
  end

  @doc """
  Counts payments based on optional filters for admin dashboard metrics.

  ## Options

    * `:status` - Count payments with specific status (can be atom or list of atoms)
    * `:since` - Count payments created since given date

  ## Examples

      iex> count_payments(status: [:pending, :processing])
      8

  """
  def count_payments(opts \\ []) do
    query =
      Payment
      |> select([p], count(p.id))
      |> maybe_filter_payment_status(opts[:status])
      |> maybe_filter_payment_since(opts[:since])

    Repo.one(query)
  end

  @doc """
  Calculates total revenue based on optional filters.

  ## Options

    * `:date` - Revenue for specific date
    * `:since` - Revenue since given date
    * `:all_time` - Total revenue (ignores other filters)
    * `:status` - Only count orders with specific status (defaults to delivered)

  ## Examples

      iex> total_revenue(date: Date.utc_today())
      #Decimal<450.75>

      iex> total_revenue(all_time: true)
      #Decimal<125000.00>

  """
  def total_revenue(opts \\ []) do
    query =
      Order
      |> select([o], coalesce(sum(o.total_price), 0))
      |> maybe_filter_order_date(opts[:date])
      |> maybe_filter_order_since(unless(opts[:all_time], do: opts[:since]))
      |> maybe_filter_order_status(opts[:status] || :delivered)

    Repo.one(query) || Decimal.new(0)
  end

  # Private filter functions

  defp maybe_filter_order_status(query, nil), do: query

  defp maybe_filter_order_status(query, status) when is_atom(status) do
    status_str = to_string(status)
    where(query, [o], o.status == ^status_str)
  end

  defp maybe_filter_order_status(query, statuses) when is_list(statuses) do
    status_strs = Enum.map(statuses, &to_string/1)
    where(query, [o], o.status in ^status_strs)
  end

  defp maybe_filter_order_date(query, nil), do: query

  defp maybe_filter_order_date(query, date) do
    {:ok, start_datetime} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
    {:ok, end_datetime} = DateTime.new(date, ~T[23:59:59], "Etc/UTC")
    where(query, [o], o.inserted_at >= ^start_datetime and o.inserted_at <= ^end_datetime)
  end

  defp maybe_filter_order_since(query, nil), do: query

  defp maybe_filter_order_since(query, date) do
    {:ok, datetime} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
    where(query, [o], o.inserted_at >= ^datetime)
  end

  defp maybe_filter_order_customer(query, nil), do: query

  defp maybe_filter_order_customer(query, customer_id),
    do: where(query, [o], o.customer_id == ^customer_id)

  defp maybe_filter_order_restaurant(query, nil), do: query

  defp maybe_filter_order_restaurant(query, restaurant_id),
    do: where(query, [o], o.restaurant_id == ^restaurant_id)

  defp maybe_filter_payment_status(query, nil), do: query

  defp maybe_filter_payment_status(query, status) when is_atom(status) do
    status_str = to_string(status)
    where(query, [p], p.status == ^status_str)
  end

  defp maybe_filter_payment_status(query, statuses) when is_list(statuses) do
    status_strs = Enum.map(statuses, &to_string/1)
    where(query, [p], p.status in ^status_strs)
  end

  defp maybe_filter_payment_since(query, nil), do: query

  defp maybe_filter_payment_since(query, date) do
    {:ok, datetime} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
    where(query, [p], p.inserted_at >= ^datetime)
  end

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
  Counts pending orders for a restaurant that need confirmation.

  Returns the number of orders with status "pending" for the given restaurant.
  Used by restaurant dashboard to show at-a-glance order confirmation needs.

  ## Examples

      iex> count_pending_confirmations(restaurant_id)
      3

  """
  def count_pending_confirmations(restaurant_id) do
    count_restaurant_orders_by_status(restaurant_id, "pending")
  end

  @doc """
  Counts active orders for a restaurant (confirmed through out_for_delivery).

  Returns the number of orders that are currently being processed by the restaurant.
  Includes statuses: "confirmed", "preparing", "ready", "out_for_delivery".
  Excludes: "pending", "delivered", "cancelled".

  ## Examples

      iex> count_active_orders(restaurant_id)
      12

  """
  def count_active_orders(restaurant_id) do
    count_restaurant_orders_by_status(restaurant_id, [
      "confirmed",
      "preparing",
      "ready",
      "out_for_delivery"
    ])
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
    # Generate tracking token for anonymous orders
    attrs =
      if is_nil(attrs[:customer_id]) and is_nil(attrs[:tracking_token]) do
        Map.put(attrs, :tracking_token, Order.generate_tracking_token())
      else
        attrs
      end

    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates an anonymous order with a soft account.

  This function creates a "soft account" (unconfirmed user) for the customer
  email and associates the order with it. This ensures all orders have a
  customer_id while still supporting the anonymous ordering flow.
  """
  def create_anonymous_order(attrs) when is_map(attrs) do
    customer_email = attrs[:customer_email] || attrs["customer_email"]

    if customer_email do
      Repo.transaction(fn ->
        # Create or get existing soft account
        case Eatfair.Accounts.create_soft_account(customer_email) do
          {:ok, soft_user} ->
            # Create order with soft account user_id and tracking token
            order_attrs =
              attrs
              |> Map.put(:customer_id, soft_user.id)
              |> Map.put(
                :tracking_token,
                attrs[:tracking_token] || Order.generate_tracking_token()
              )
              |> Map.put(:email_status, "unverified")

            case create_order(order_attrs) do
              {:ok, order} -> order
              {:error, changeset} -> Repo.rollback(changeset)
            end

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    else
      {:error, :missing_customer_email}
    end
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
  Returns a changeset for validating order details (email, phone, address, etc.).
  This is used for the streamlined ordering flow without user accounts.
  """
  def change_order_details(attrs \\ %{}) do
    import Ecto.Changeset

    data = %{}

    types = %{
      email: :string,
      delivery_address: :string,
      phone_number: :string,
      delivery_time: :string,
      special_instructions: :string
    }

    {data, types}
    |> cast(attrs, Map.keys(types))
    |> validate_required([:email, :delivery_address, :phone_number, :delivery_time])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
      message: "must be a valid email address"
    )
    |> validate_length(:phone_number, min: 8, max: 20, message: "must be a valid phone number")
    |> validate_length(:delivery_address,
      min: 10,
      message: "must include complete address with street, city, and postal code"
    )
    |> validate_format(:phone_number, ~r/^[\+]?[0-9\s\-\(\)]+$/,
      message: "must be a valid phone number format"
    )
    |> validate_length(:special_instructions, max: 500, message: "cannot exceed 500 characters")
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
          Map.take(attrs, [
            :delay_reason,
            :estimated_delivery_at,
            :rejection_reason,
            :rejection_notes,
            :failure_reason,
            :failure_notes
          ])
        )

        # Create refund if order is rejected or delivery failed
        maybe_create_refund(updated_order, new_status, attrs)

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
    list_restaurant_orders(restaurant_id, :active)
  end

  @doc """
  Lists orders for a restaurant with filtering support.
  
  ## Parameters
  - restaurant_id: The ID of the restaurant
  - filter: :active (default) for pending/confirmed/preparing/ready/out_for_delivery, or :history for delivered/cancelled
  """
  def list_restaurant_orders(restaurant_id, filter) when filter in [:active, :history] do
    statuses = case filter do
      :active -> ["pending", "confirmed", "preparing", "ready", "out_for_delivery"]
      :history -> ["delivered", "cancelled", "delivery_failed"]
    end
    
    orders = Order
    |> where([o], o.restaurant_id == ^restaurant_id)
    |> where([o], o.status in ^statuses)
    |> preload([:customer, order_items: :meal, delivery_batch: :courier])
    |> order_by([o], desc: :inserted_at)  # History shows most recent first
    |> Repo.all()
    
    case filter do
      :active -> group_orders_by_status(orders)
      :history -> orders  # History returns flat list, not grouped
    end
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
  Gets the most recent order for a customer.

  This is useful for account setup flows after email verification
  to redirect to the appropriate order tracking page.

  Returns the most recent order or nil if no orders exist.
  """
  def get_latest_customer_order(customer_id) when is_integer(customer_id) do
    Order
    |> where([o], o.customer_id == ^customer_id)
    |> preload([:restaurant, order_items: :meal])
    |> order_by([o], desc: o.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_latest_customer_order(nil), do: nil

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
  Lists orders by delivery status.
  """
  def list_orders_by_delivery_status(delivery_status) do
    Order
    |> where([o], o.delivery_status == ^delivery_status)
    |> preload([:customer, :restaurant, order_items: :meal])
    |> order_by([o], desc: o.inserted_at)
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

  # Helper function for restaurant order counts
  defp count_restaurant_orders_by_status(restaurant_id, status) when is_binary(status) do
    Order
    |> select([o], count(o.id))
    |> where([o], o.restaurant_id == ^restaurant_id)
    |> where([o], o.status == ^status)
    |> Repo.one()
  end

  defp count_restaurant_orders_by_status(restaurant_id, statuses) when is_list(statuses) do
    Order
    |> select([o], count(o.id))
    |> where([o], o.restaurant_id == ^restaurant_id)
    |> where([o], o.status in ^statuses)
    |> Repo.one()
  end

  defp add_status_timestamp(attrs, status, timestamp) do
    case status do
      "confirmed" -> Map.put(attrs, :confirmed_at, timestamp)
      "preparing" -> Map.put(attrs, :preparing_at, timestamp)
      "ready" -> Map.put(attrs, :ready_at, timestamp)
      "out_for_delivery" -> Map.put(attrs, :out_for_delivery_at, timestamp)
      "delivered" -> Map.put(attrs, :delivered_at, timestamp)
      "cancelled" -> Map.put(attrs, :cancelled_at, timestamp)
      # No specific timestamp for rejected, use general timestamps
      "rejected" -> attrs
      # No specific timestamp for delivery_failed, use general timestamps
      "delivery_failed" -> attrs
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
      pending: Enum.filter(orders, &(&1.status == "pending")),
      confirmed: Enum.filter(orders, &(&1.status == "confirmed")),
      preparing: Enum.filter(orders, &(&1.status == "preparing")),
      ready: Enum.filter(orders, &(&1.status == "ready")),
      out_for_delivery: Enum.filter(orders, &(&1.status == "out_for_delivery"))
    }
  end

  # Email verification functions

  @doc """
  Updates the email verification status for an order.
  """
  def update_order_email_status(order_id, status)
      when status in ["unverified", "pending", "verified"] do
    now = DateTime.utc_now()

    attrs = %{email_status: status}
    attrs = if status == "verified", do: Map.put(attrs, :email_verified_at, now), else: attrs

    order = get_order!(order_id)
    result = update_order(order, attrs)

    # Broadcast email verification status change
    case result do
      {:ok, updated_order} ->
        broadcast_email_verification(updated_order)
        result

      error ->
        error
    end
  end

  @doc """
  Gets an order by its tracking token (for anonymous tracking).
  """
  def get_order_by_tracking_token(nil), do: nil

  def get_order_by_tracking_token(token) when is_binary(token) do
    Order
    |> where([o], o.tracking_token == ^token)
    |> preload([:restaurant, order_items: :meal])
    |> Repo.one()
  end

  @doc """
  Gets orders by customer email (for anonymous orders and soft accounts).

  This function finds orders both by:
  1. Direct customer_email field (legacy orders)
  2. Associated user email for soft accounts
  """
  def list_orders_by_email(email) when is_binary(email) do
    Order
    |> join(:left, [o], u in Eatfair.Accounts.User, on: o.customer_id == u.id)
    |> where([o, u], o.customer_email == ^email or u.email == ^email)
    |> preload([:restaurant, order_items: :meal])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Associates an anonymous order with a user account after account creation.
  """
  def associate_order_with_user(order_id, user_id) do
    order = get_order!(order_id)

    attrs = %{
      customer_id: user_id,
      account_created_from_order: true
    }

    update_order(order, attrs)
  end

  @doc """
  Checks if an email address has any associated orders (for account creation).
  """
  def email_has_orders?(email) when is_binary(email) do
    query = from o in Order, where: o.customer_email == ^email, limit: 1
    Repo.exists?(query)
  end

  # Private helper functions for email verification

  defp broadcast_email_verification(order) do
    email = Order.primary_email(order)

    if email do
      Phoenix.PubSub.broadcast(
        Eatfair.PubSub,
        "email_verification:#{email}",
        {:email_verified, email}
      )

      # Also broadcast to order-specific channel if tracking token exists
      if order.tracking_token do
        Phoenix.PubSub.broadcast(
          Eatfair.PubSub,
          "order_tracking:#{order.tracking_token}",
          {:email_verified, order}
        )
      end
    end
  end

  # Order tracking audit trail functions

  @doc """
  Creates a new order status event for audit trail tracking.

  This function creates an immutable record of order status changes,
  maintaining a complete audit trail. It also handles automatic 
  status transitions and broadcasts real-time updates.
  """
  def create_order_status_event(attrs) do
    # Sanitize metadata to ensure all values are JSON-serializable
    sanitized_attrs =
      case attrs[:metadata] || attrs["metadata"] do
        nil -> attrs
        metadata -> Map.put(attrs, :metadata, sanitize_metadata(metadata))
      end

    changeset = OrderStatusEvent.create_changeset(sanitized_attrs)

    case Repo.insert(changeset) do
      {:ok, event} ->
        # Broadcast real-time status update
        broadcast_status_event(event)

        # Handle automatic status transitions if needed
        handle_automatic_transitions(event)

        {:ok, event}

      error ->
        error
    end
  end

  @doc """
  Gets the current status of an order by querying the most recent status event.
  """
  def get_current_order_status(order_id) do
    OrderStatusEvent
    |> where([e], e.order_id == ^order_id)
    |> order_by([e], desc: e.occurred_at, desc: e.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Gets the complete status history for an order, ordered chronologically.
  """
  def get_order_status_history(order_id) do
    OrderStatusEvent
    |> where([e], e.order_id == ^order_id)
    |> preload([:actor])
    |> order_by([e], asc: e.occurred_at, asc: e.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets order tracking data including current status and location if available.
  This is the main function for the customer order tracking interface.
  """
  def get_order_tracking_data(order_id) when is_integer(order_id) do
    with order when not is_nil(order) <- get_order_with_tracking(order_id) do
      current_status = get_current_order_status(order_id)
      status_history = get_order_status_history(order_id)

      # If no status events exist, create initial tracking event for backward compatibility
      {current_status, status_history} =
        if is_nil(current_status) and length(status_history) == 0 do
          # Initialize tracking for existing orders
          {:ok, initial_event} =
            initialize_order_tracking(order_id, %{
              total_amount: order.total_price,
              delivery_address_id: nil,
              requested_delivery_time: order.estimated_delivery_at
            })

          {initial_event, [initial_event]}
        else
          {current_status, status_history}
        end

      tracking_data = %{
        order: order,
        current_status: current_status,
        status_history: status_history
      }

      # Add location data if order is in transit
      final_tracking_data =
        if current_status && current_status.status == "in_transit" do
          location_update = get_latest_courier_location(order_id)
          Map.put(tracking_data, :courier_location, location_update)
        else
          tracking_data
        end

      {:ok, final_tracking_data}
    else
      nil -> {:error, :order_not_found}
    end
  end

  @doc """
  Gets order tracking data by tracking token (for anonymous access).
  """
  def get_order_tracking_by_token(token) when is_binary(token) do
    case get_order_by_tracking_token(token) do
      nil -> {:error, :invalid_token}
      order -> get_order_tracking_data(order.id)
    end
  end

  @doc """
  Transitions an order to a new status with audit trail.

  This is the main function for status transitions in the new system.
  It creates an audit event and optionally updates the old status fields
  for backwards compatibility.
  """
  def transition_order_status(order_id, new_status, attrs \\ %{}) when is_integer(order_id) do
    attrs = Map.put(attrs, :order_id, order_id)
    attrs = Map.put(attrs, :status, new_status)

    Repo.transaction(fn ->
      # Create the audit trail event
      case create_order_status_event(attrs) do
        {:ok, event} ->
          # For backwards compatibility, also update the order's status field
          order = get_order!(order_id)
          {:ok, updated_order} = update_order_legacy_status(order, new_status)

          %{event: event, order: updated_order}

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates a courier location update.
  """
  def create_courier_location_update(attrs) do
    changeset = CourierLocationUpdate.create_changeset(attrs)

    case Repo.insert(changeset) do
      {:ok, update} ->
        # Broadcast location update to tracking interfaces
        broadcast_location_update(update)
        {:ok, update}

      error ->
        error
    end
  end

  @doc """
  Gets the latest courier location for an order.
  """
  def get_latest_courier_location(order_id) do
    CourierLocationUpdate
    |> where([u], u.order_id == ^order_id)
    |> preload([:courier])
    |> order_by([u], desc: u.recorded_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Gets courier location history for an order.
  """
  def get_courier_location_history(order_id) do
    CourierLocationUpdate
    |> where([u], u.order_id == ^order_id)
    |> preload([:courier])
    |> order_by([u], asc: u.recorded_at)
    |> Repo.all()
  end

  @doc """
  Initializes order tracking by creating the initial "order_placed" event.
  This should be called immediately after order creation.
  """
  def initialize_order_tracking(order_id, attrs \\ %{}) do
    event_attrs =
      attrs
      |> Map.put(:order_id, order_id)
      |> Map.put(:status, "order_placed")
      |> Map.put(:actor_type, "system")
      |> Map.put_new(:metadata, %{
        total_amount: attrs[:total_amount],
        delivery_address_id: attrs[:delivery_address_id],
        requested_delivery_time: attrs[:requested_delivery_time]
      })

    create_order_status_event(event_attrs)
  end

  # Private helper functions for order tracking

  defp get_order_with_tracking(order_id) do
    Order
    |> where([o], o.id == ^order_id)
    |> preload([:customer, :restaurant, order_items: :meal])
    |> Repo.one()
  end

  defp update_order_legacy_status(order, new_status) do
    # Map new status names to old status names for backwards compatibility
    legacy_status = map_to_legacy_status(new_status)
    update_order_status(order, legacy_status)
  end

  defp map_to_legacy_status("order_placed"), do: "pending"
  defp map_to_legacy_status("order_accepted"), do: "confirmed"
  defp map_to_legacy_status("cooking"), do: "preparing"
  defp map_to_legacy_status("ready_for_courier"), do: "ready"
  defp map_to_legacy_status("in_transit"), do: "out_for_delivery"
  defp map_to_legacy_status("delivered"), do: "delivered"
  defp map_to_legacy_status("order_rejected"), do: "cancelled"
  defp map_to_legacy_status("delivery_failed"), do: "cancelled"
  defp map_to_legacy_status(status), do: status

  defp broadcast_status_event(event) do
    order = get_order!(event.order_id)

    # Broadcast to customer tracking
    Phoenix.PubSub.broadcast(
      Eatfair.PubSub,
      "order_tracking:#{order.id}",
      {:status_event_created, event}
    )

    # Broadcast to token-based tracking for anonymous users
    if order.tracking_token do
      Phoenix.PubSub.broadcast(
        Eatfair.PubSub,
        "order_tracking_token:#{order.tracking_token}",
        {:status_event_created, event}
      )
    end
  end

  defp broadcast_location_update(update) do
    Phoenix.PubSub.broadcast(
      Eatfair.PubSub,
      "order_tracking:#{update.order_id}",
      {:location_updated, update}
    )

    # Also broadcast to token-based tracking
    order = get_order!(update.order_id)

    if order.tracking_token do
      Phoenix.PubSub.broadcast(
        Eatfair.PubSub,
        "order_tracking_token:#{order.tracking_token}",
        {:location_updated, update}
      )
    end
  end

  defp handle_automatic_transitions(event) do
    # Handle automatic status transitions based on business logic
    case event.status do
      "order_accepted" ->
        # Automatically transition to cooking based on preparation timing
        maybe_auto_transition_to_cooking(event)

      _ ->
        :ok
    end
  end

  defp maybe_auto_transition_to_cooking(_event) do
    # This would implement automatic transition logic
    # For now, we'll leave it as a placeholder for future enhancement
    :ok
  end

  # Metadata sanitization helper to ensure JSON serialization compatibility

  defp sanitize_metadata(metadata) when is_map(metadata) do
    Enum.into(metadata, %{}, fn {key, value} ->
      {key, sanitize_metadata_value(value)}
    end)
  end

  defp sanitize_metadata(value), do: sanitize_metadata_value(value)

  defp sanitize_metadata_value(%Decimal{} = decimal) do
    Decimal.to_float(decimal)
  end

  defp sanitize_metadata_value(value) when is_map(value) do
    sanitize_metadata(value)
  end

  defp sanitize_metadata_value(value), do: value

  # Helper function to create refunds when appropriate
  defp maybe_create_refund(order, new_status, attrs) do
    case new_status do
      "cancelled" ->
        # Order was rejected - create a refund
        reason_details = build_refund_reason_details("order_rejected", attrs)

        case Refunds.create_refund_for_order(order, %{
               reason: "order_rejected",
               reason_details: reason_details
             }) do
          {:ok, _refund} -> :ok
          # Log error but don't fail the order update
          {:error, _changeset} -> :ok
        end

      "delivery_failed" ->
        # Delivery failed - create a refund
        reason_details = build_refund_reason_details("delivery_failed", attrs)

        case Refunds.create_refund_for_order(order, %{
               reason: "delivery_failed",
               reason_details: reason_details
             }) do
          {:ok, _refund} -> :ok
          # Log error but don't fail the order update
          {:error, _changeset} -> :ok
        end

      _ ->
        :ok
    end
  end

  defp build_refund_reason_details("order_rejected", attrs) do
    rejection_reason = attrs[:rejection_reason] || "order_rejected"
    rejection_notes = attrs[:rejection_notes]

    details = "Order rejected - #{rejection_reason}"

    if rejection_notes do
      details <> ": #{rejection_notes}"
    else
      details
    end
  end

  defp build_refund_reason_details("delivery_failed", attrs) do
    failure_reason = attrs[:failure_reason] || "delivery_failed"
    failure_notes = attrs[:failure_notes]

    details = "Delivery failed - #{failure_reason}"

    if failure_notes do
      details <> ": #{failure_notes}"
    else
      details
    end
  end

  @doc """
  Accepts the customer's desired ETA for an order.
  Marks eta_accepted as true and clears any pending proposals.
  """
  def accept_desired_eta(%Order{} = order) do
    order
    |> Order.changeset(%{
      eta_accepted: true,
      eta_pending: false,
      proposed_eta: nil
    })
    |> Repo.update()
    |> case do
      {:ok, updated_order} ->
        # Preload associations for notifications
        updated_order = updated_order |> Repo.preload([:restaurant, :customer])
        # Create notification event
        create_eta_notification(updated_order, "eta_accepted")
        {:ok, updated_order}

      error ->
        error
    end
  end

  @doc """
  Proposes an alternative ETA for an order.
  Sets eta_pending to true and stores the proposed time.
  """
  def propose_alternative_eta(%Order{} = order, proposed_time) do
    order
    |> Order.changeset(%{
      eta_accepted: false,
      eta_pending: true,
      proposed_eta: proposed_time
    })
    |> Repo.update()
    |> case do
      {:ok, updated_order} ->
        # Preload associations for notifications  
        updated_order = updated_order |> Repo.preload([:restaurant, :customer])
        # Create notification event
        create_eta_notification(updated_order, "eta_proposed")
        {:ok, updated_order}

      error ->
        error
    end
  end

  @doc """
  Accepts a restaurant's proposed ETA.
  Updates the desired_delivery_at to the proposed time and marks as accepted.
  """
  def accept_proposed_eta(%Order{} = order) do
    case order.proposed_eta do
      nil ->
        {:error, "No proposed ETA to accept"}

      proposed_time ->
        order
        |> Order.changeset(%{
          desired_delivery_at: proposed_time,
          eta_accepted: true,
          eta_pending: false,
          proposed_eta: nil
        })
        |> Repo.update()
        |> case do
          {:ok, updated_order} ->
            # Create notification event
            create_eta_notification(updated_order, "eta_accepted_by_customer")
            {:ok, updated_order}

          error ->
            error
        end
    end
  end

  # Helper function to create ETA-related notifications
  defp create_eta_notification(order, event_type) do
    case event_type do
      "eta_accepted" ->
        Notifications.create_event(%{
          event_type: "eta_accepted",
          recipient_id: order.customer_id,
          priority: "normal",
          data: %{
            order_id: order.id,
            restaurant_name: order.restaurant.name,
            message: "Your desired delivery time has been confirmed!"
          }
        })

      "eta_proposed" ->
        Notifications.create_event(%{
          event_type: "eta_proposed",
          recipient_id: order.customer_id,
          priority: "high",
          data: %{
            order_id: order.id,
            restaurant_name: order.restaurant.name,
            proposed_eta: order.proposed_eta,
            message: "The restaurant has proposed a different delivery time"
          }
        })

      "eta_accepted_by_customer" ->
        # Notify restaurant that customer accepted their proposal
        Notifications.create_event(%{
          event_type: "eta_accepted_by_customer",
          recipient_id: order.restaurant.owner_id,
          priority: "normal",
          data: %{
            order_id: order.id,
            customer_email: primary_email(order),
            message: "Customer accepted your proposed delivery time"
          }
        })
    end
  rescue
    # Don't fail the order update if notification creation fails
    _error -> :ok
  end

  # Helper to get primary email from order
  defp primary_email(%Order{customer_id: nil, customer_email: email}), do: email
  defp primary_email(%Order{customer: %{email: email}}), do: email
  defp primary_email(_), do: nil

  # ============================================================================
  # DELIVERY BATCH MANAGEMENT FUNCTIONS
  # ============================================================================

  @doc """
  Creates a delivery batch.
  """
  def create_delivery_batch(attrs \\ %{}) do
    %DeliveryBatch{}
    |> DeliveryBatch.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a delivery batch.
  """
  def update_delivery_batch(%DeliveryBatch{} = batch, attrs) do
    batch
    |> DeliveryBatch.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates delivery batch status.
  """
  def update_delivery_batch_status(%DeliveryBatch{} = batch, new_status) do
    update_delivery_batch(batch, %{status: new_status})
  end

  @doc """
  Gets a delivery batch with preloaded orders.
  """
  def get_delivery_batch_with_orders(id) do
    DeliveryBatch
    |> preload([:courier, :restaurant, orders: [:customer, :restaurant, order_items: :meal]])
    |> Repo.get!(id)
  end

  @doc """
  Lists delivery batches for a restaurant.
  """
  def list_restaurant_delivery_batches(restaurant_id) do
    DeliveryBatch
    |> where([b], b.restaurant_id == ^restaurant_id)
    |> preload([:courier, orders: [:customer]])
    |> order_by([b], desc: b.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists delivery batches for a courier.
  """
  def list_courier_delivery_batches(courier_id) do
    DeliveryBatch
    |> where([b], b.courier_id == ^courier_id)
    |> where([b], b.status not in ["draft", "cancelled"])
    |> preload([:restaurant, orders: [:customer]])
    |> order_by([b], asc: b.scheduled_pickup_time)
    |> Repo.all()
  end

  @doc """
  Assigns orders to a delivery batch.
  Updates the orders' delivery_batch_id and sets their delivery_status to "scheduled".
  """
  def assign_orders_to_batch(batch_id, order_ids) do
    Repo.transaction(fn ->
      # Update all orders to be assigned to this batch
      {count, _} = 
        from(o in Order, where: o.id in ^order_ids)
        |> Repo.update_all(set: [
          delivery_batch_id: batch_id,
          delivery_status: "scheduled",
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        ])

      if count == length(order_ids) do
        # Get the updated batch
        batch = get_delivery_batch_with_orders(batch_id)
        batch
      else
        Repo.rollback("Failed to assign all orders to batch")
      end
    end)
  end

  @doc """
  Counts delivery batches by status for a courier.
  Returns a map with status as keys and counts as values.
  """
  def count_courier_batches_by_status(courier_id) do
    DeliveryBatch
    |> where([b], b.courier_id == ^courier_id)
    |> where([b], b.status not in ["draft", "cancelled"])
    |> group_by([b], b.status)
    |> select([b], {b.status, count(b.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc """
  Counts completed delivery batches for a courier today.
  """
  def count_courier_completed_batches_today(courier_id) do
    today_start = DateTime.utc_now() |> DateTime.to_date() |> DateTime.new!(~T[00:00:00])
    today_end = DateTime.add(today_start, 1, :day)

    DeliveryBatch
    |> where([b], b.courier_id == ^courier_id)
    |> where([b], b.status == "completed")
    |> where([b], b.updated_at >= ^today_start and b.updated_at < ^today_end)
    |> Repo.aggregate(:count, :id)
  end
end
