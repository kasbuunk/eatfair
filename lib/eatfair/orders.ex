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
      Enum.map(items_attrs, fn attrs -> 
        attrs
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
      |> Map.put(:provider_transaction_id, "mock_#{:rand.uniform(1000000)}")

    case create_payment(payment_attrs) do
      {:ok, payment} ->
        # Update order status to confirmed
        order = get_order!(order_id)
        update_order(order, %{status: "confirmed"})
        {:ok, payment}
      
      error -> error
    end
  end
end
