defmodule Eatfair.OrdersFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the `Eatfair.Orders` context.
  """

  alias Eatfair.Orders

  def order_fixture(attrs \\ %{}) do
    customer = attrs[:customer] || Eatfair.AccountsFixtures.user_fixture()
    restaurant = attrs[:restaurant] || Eatfair.RestaurantsFixtures.restaurant_fixture()

    order_attrs =
      attrs
      |> Enum.into(%{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        total_price: Decimal.new("25.50"),
        delivery_address: "Test Address 123, 1234AB Test City",
        delivery_notes: "Test delivery notes",
        status: "pending"
      })

    {:ok, order} = Orders.create_order(order_attrs)

    # Preload associations like the main context function does
    Orders.get_order!(order.id)
  end

  def order_with_items_fixture(attrs \\ %{}) do
    customer = attrs[:customer] || Eatfair.AccountsFixtures.user_fixture()
    restaurant = attrs[:restaurant] || Eatfair.RestaurantsFixtures.restaurant_fixture()

    meal =
      attrs[:meal] || Eatfair.RestaurantsFixtures.meal_fixture(%{restaurant_id: restaurant.id})

    order_attrs =
      attrs
      |> Map.drop([:customer, :restaurant, :meal, :items])
      |> Enum.into(%{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        total_price: meal.price,
        delivery_address: "Test Address 123, 1234AB Test City",
        delivery_notes: "Test delivery notes",
        status: "confirmed"
      })

    items_attrs = attrs[:items] || [%{meal_id: meal.id, quantity: 2}]

    case Orders.create_order_with_items(order_attrs, items_attrs) do
      {:ok, order} -> order
      {:error, error} -> raise "Failed to create order with items: #{inspect(error)}"
    end
  end

  def payment_fixture(attrs \\ %{}) do
    order = attrs[:order] || order_fixture()

    payment_attrs =
      attrs
      |> Enum.into(%{
        order_id: order.id,
        amount: order.total_price,
        status: "completed",
        provider: "test_provider",
        provider_transaction_id: "test_txn_#{:rand.uniform(1_000_000)}"
      })

    {:ok, payment} = Orders.create_payment(payment_attrs)
    payment
  end
end
