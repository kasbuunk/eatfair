defmodule Eatfair.Orders.DeliveryStatusTest do
  use Eatfair.DataCase

  alias Eatfair.Orders.Order
  alias Eatfair.Orders

  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  describe "delivery_status field" do
    test "order has delivery_status field with default not_ready" do
      customer = user_fixture(%{role: "customer"})
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      assert order.delivery_status == "not_ready"
    end

    test "delivery_status can be set to valid values" do
      customer = user_fixture(%{role: "customer"})
      restaurant = restaurant_fixture()

      # Create a minimal valid order to test delivery_status
      base_order_attrs = %{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        delivery_address: "Test Address",
        total_price: Decimal.new("10.00")
      }

      order = %Order{}
      valid_statuses = ["not_ready", "staged", "scheduled", "in_transit", "delivered"]

      Enum.each(valid_statuses, fn status ->
        changeset = Order.changeset(order, Map.put(base_order_attrs, :delivery_status, status))

        assert changeset.valid?,
               "#{status} should be valid, but got errors: #{inspect(changeset.errors)}"

        assert Ecto.Changeset.get_field(changeset, :delivery_status) == status
      end)
    end

    test "delivery_status rejects invalid values" do
      customer = user_fixture(%{role: "customer"})
      restaurant = restaurant_fixture()

      # Create a minimal valid order to test delivery_status
      base_order_attrs = %{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        delivery_address: "Test Address",
        total_price: Decimal.new("10.00")
      }

      order = %Order{}
      invalid_statuses = ["invalid_status", "unknown", "bad_status"]

      Enum.each(invalid_statuses, fn status ->
        changeset = Order.changeset(order, Map.put(base_order_attrs, :delivery_status, status))
        refute changeset.valid?, "#{status} should be invalid"

        assert changeset.errors[:delivery_status] != nil,
               "Should have error for delivery_status when status is #{inspect(status)}"
      end)

      # Test nil separately as it should use the default value
      changeset = Order.changeset(order, base_order_attrs)
      assert changeset.valid?, "nil delivery_status should use default and be valid"
    end
  end

  describe "dual status system - preparation vs delivery" do
    test "order can have different preparation and delivery statuses" do
      customer = user_fixture(%{role: "customer"})
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address",
            # preparation status
            status: "preparing",
            # delivery status
            delivery_status: "not_ready"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      assert order.status == "preparing"
      assert order.delivery_status == "not_ready"
    end

    test "delivery status can progress independently of preparation status" do
      customer = user_fixture(%{role: "customer"})
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address",
            status: "ready"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Update delivery status while keeping preparation status
      {:ok, updated_order} =
        Orders.update_order(order, %{delivery_status: "staged"})

      # preparation unchanged
      assert updated_order.status == "ready"
      assert updated_order.delivery_status == "staged"
    end

    test "delivery status transitions follow logical progression" do
      customer = user_fixture(%{role: "customer"})
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address",
            status: "ready"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Progression: not_ready -> staged -> scheduled -> in_transit -> delivered
      {:ok, staged_order} =
        Orders.update_order(order, %{delivery_status: "staged"})

      assert staged_order.delivery_status == "staged"

      {:ok, scheduled_order} =
        Orders.update_order(staged_order, %{delivery_status: "scheduled"})

      assert scheduled_order.delivery_status == "scheduled"

      {:ok, in_transit_order} =
        Orders.update_order(scheduled_order, %{delivery_status: "in_transit"})

      assert in_transit_order.delivery_status == "in_transit"

      {:ok, delivered_order} =
        Orders.update_order(in_transit_order, %{delivery_status: "delivered"})

      assert delivered_order.delivery_status == "delivered"
    end
  end

  describe "querying orders by delivery status" do
    test "can filter orders by delivery status" do
      customer = user_fixture(%{role: "customer"})
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      # Create orders with different delivery statuses
      {:ok, not_ready_order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address 1",
            delivery_status: "not_ready"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, staged_order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address 2",
            delivery_status: "staged"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Query orders by delivery status
      not_ready_orders = Orders.list_orders_by_delivery_status("not_ready")
      staged_orders = Orders.list_orders_by_delivery_status("staged")

      assert length(not_ready_orders) >= 1
      assert length(staged_orders) >= 1
      assert Enum.any?(not_ready_orders, fn o -> o.id == not_ready_order.id end)
      assert Enum.any?(staged_orders, fn o -> o.id == staged_order.id end)
    end
  end
end
