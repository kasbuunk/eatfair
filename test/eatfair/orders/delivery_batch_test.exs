defmodule Eatfair.Orders.DeliveryBatchTest do
  use Eatfair.DataCase

  alias Eatfair.Orders

  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  describe "delivery batch management" do
    test "can create delivery batch with valid attributes" do
      restaurant = restaurant_fixture()
      courier = user_fixture(%{role: "courier"})

      batch_attrs = %{
        name: "Evening Batch #1",
        restaurant_id: restaurant.id,
        courier_id: courier.id,
        # 1 hour from now
        scheduled_pickup_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 3600),
        # 2 hours from now
        estimated_delivery_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 7200),
        notes: "Deliver to building entrance"
      }

      {:ok, batch} = Orders.create_delivery_batch(batch_attrs)

      assert batch.name == "Evening Batch #1"
      assert batch.status == "draft"
      assert batch.restaurant_id == restaurant.id
      assert batch.courier_id == courier.id
    end

    test "validates required fields" do
      batch_attrs = %{
        name: "",
        scheduled_pickup_time: nil
      }

      {:error, changeset} = Orders.create_delivery_batch(batch_attrs)

      assert changeset.errors[:name] != nil
      assert changeset.errors[:restaurant_id] != nil
    end

    test "validates delivery batch status transitions" do
      restaurant = restaurant_fixture()
      courier = user_fixture(%{role: "courier"})

      {:ok, batch} =
        Orders.create_delivery_batch(%{
          name: "Test Batch",
          restaurant_id: restaurant.id,
          courier_id: courier.id,
          scheduled_pickup_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 3600),
          estimated_delivery_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 7200)
        })

      # Should be able to propose to courier
      {:ok, proposed_batch} = Orders.update_delivery_batch_status(batch, "proposed")
      assert proposed_batch.status == "proposed"

      # Should be able to accept
      {:ok, accepted_batch} = Orders.update_delivery_batch_status(proposed_batch, "accepted")
      assert accepted_batch.status == "accepted"
    end

    test "can assign orders to delivery batch" do
      restaurant = restaurant_fixture()
      courier = user_fixture(%{role: "courier"})
      customer = user_fixture(%{role: "customer"})
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, batch} =
        Orders.create_delivery_batch(%{
          name: "Test Batch",
          restaurant_id: restaurant.id,
          courier_id: courier.id,
          scheduled_pickup_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 3600),
          estimated_delivery_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 7200)
        })

      # Create orders
      {:ok, order1} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address 1",
            status: "ready"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, order2} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address 2",
            status: "ready"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Assign orders to batch
      {:ok, updated_batch} = Orders.assign_orders_to_batch(batch.id, [order1.id, order2.id])

      batch_with_orders = Orders.get_delivery_batch_with_orders(updated_batch.id)
      assert length(batch_with_orders.orders) == 2

      # Orders should be updated to scheduled delivery status
      updated_order1 = Orders.get_order!(order1.id)
      updated_order2 = Orders.get_order!(order2.id)
      assert updated_order1.delivery_status == "scheduled"
      assert updated_order2.delivery_status == "scheduled"
      assert updated_order1.delivery_batch_id == batch.id
      assert updated_order2.delivery_batch_id == batch.id
    end

    test "can list delivery batches for restaurant" do
      restaurant = restaurant_fixture()
      courier = user_fixture(%{role: "courier"})

      {:ok, _batch1} =
        Orders.create_delivery_batch(%{
          name: "Morning Batch",
          restaurant_id: restaurant.id,
          courier_id: courier.id,
          scheduled_pickup_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 3600),
          estimated_delivery_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 7200)
        })

      {:ok, _batch2} =
        Orders.create_delivery_batch(%{
          name: "Evening Batch",
          restaurant_id: restaurant.id,
          courier_id: courier.id,
          scheduled_pickup_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 14400),
          estimated_delivery_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 18000)
        })

      batches = Orders.list_restaurant_delivery_batches(restaurant.id)
      assert length(batches) == 2
    end

    test "can list delivery batches for courier" do
      restaurant = restaurant_fixture()
      courier = user_fixture(%{role: "courier"})

      {:ok, _batch} =
        Orders.create_delivery_batch(%{
          name: "Courier Batch",
          restaurant_id: restaurant.id,
          courier_id: courier.id,
          status: "accepted",
          scheduled_pickup_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 3600),
          estimated_delivery_time: NaiveDateTime.add(NaiveDateTime.utc_now(), 7200)
        })

      batches = Orders.list_courier_delivery_batches(courier.id)
      assert length(batches) == 1
    end
  end
end
