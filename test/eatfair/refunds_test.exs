defmodule Eatfair.RefundsTest do
  use Eatfair.DataCase

  alias Eatfair.Refunds
  alias Eatfair.Orders

  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  describe "refunds" do
    test "create_refund_for_order/2 creates a staged refund" do
      customer = user_fixture()
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id, price: Decimal.new("25.50")})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "123 Test St",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Create a staged refund for order rejection
      {:ok, refund} =
        Refunds.create_refund_for_order(order, %{
          reason: "order_rejected",
          reason_details: "Restaurant ran out of ingredients"
        })

      assert refund.order_id == order.id
      assert refund.customer_id == customer.id
      assert refund.amount == meal.price
      assert refund.reason == "order_rejected"
      assert refund.reason_details == "Restaurant ran out of ingredients"
      assert refund.status == "pending"
      assert refund.processed_at == nil
    end

    test "create_refund_for_order/2 handles delivery failure" do
      customer = user_fixture()
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id, price: Decimal.new("15.75")})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "456 Delivery St",
            status: "out_for_delivery"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Create staged refund for delivery failure
      {:ok, refund} =
        Refunds.create_refund_for_order(order, %{
          reason: "delivery_failed",
          reason_details: "Address not found, customer unreachable"
        })

      assert refund.reason == "delivery_failed"
      assert refund.amount == meal.price
      assert refund.status == "pending"
    end

    test "list_pending_refunds/0 returns all unprocessed refunds" do
      customer1 = user_fixture()
      customer2 = user_fixture()
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order1} =
        Orders.create_order_with_items(
          %{
            customer_id: customer1.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Addr1",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, order2} =
        Orders.create_order_with_items(
          %{
            customer_id: customer2.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Addr2",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Create refunds
      {:ok, refund1} = Refunds.create_refund_for_order(order1, %{reason: "order_rejected"})
      {:ok, refund2} = Refunds.create_refund_for_order(order2, %{reason: "delivery_failed"})

      pending_refunds = Refunds.list_pending_refunds()

      assert length(pending_refunds) == 2
      refund_ids = Enum.map(pending_refunds, & &1.id)
      assert refund1.id in refund_ids
      assert refund2.id in refund_ids
    end

    test "mark_refund_processed/2 updates refund status" do
      customer = user_fixture()
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Addr",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, refund} = Refunds.create_refund_for_order(order, %{reason: "order_rejected"})

      # Mark as processed
      {:ok, processed_refund} =
        Refunds.mark_refund_processed(refund, %{
          processor_notes: "Processed via Stripe refund API",
          external_refund_id: "re_1234567890"
        })

      assert processed_refund.status == "processed"
      assert processed_refund.processor_notes == "Processed via Stripe refund API"
      assert processed_refund.external_refund_id == "re_1234567890"
      assert processed_refund.processed_at != nil
    end

    test "get_refunds_for_order/1 returns all refunds for an order" do
      customer = user_fixture()
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Addr",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Create multiple refunds (edge case - maybe partial refunds or retry scenarios)
      {:ok, _refund1} = Refunds.create_refund_for_order(order, %{reason: "order_rejected"})
      {:ok, _refund2} = Refunds.create_refund_for_order(order, %{reason: "delivery_failed"})

      refunds = Refunds.get_refunds_for_order(order.id)
      assert length(refunds) == 2
    end
  end

  describe "refund integration with order processing" do
    test "rejecting an order automatically stages a refund" do
      customer = user_fixture()
      restaurant_owner = user_fixture()
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      meal = meal_fixture(%{restaurant_id: restaurant.id, price: Decimal.new("20.00")})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Integration Test Address",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Reject the order (this should create a staged refund)
      {:ok, _updated_order} =
        Orders.update_order_status(order, "cancelled", %{
          rejection_reason: "out_of_ingredients",
          rejection_notes: "Sorry, we ran out of key ingredients"
        })

      # Should have created a staged refund
      refunds = Refunds.get_refunds_for_order(order.id)
      assert length(refunds) == 1

      refund = hd(refunds)
      assert refund.reason == "order_rejected"
      assert Decimal.equal?(refund.amount, meal.price)
      assert refund.status == "pending"
      assert String.contains?(refund.reason_details, "out_of_ingredients")
    end

    test "delivery failure automatically stages a refund" do
      customer = user_fixture()
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id, price: Decimal.new("18.50")})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Delivery Failure Address",
            status: "out_for_delivery"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Report delivery failure (this should create a staged refund)
      {:ok, _updated_order} =
        Orders.update_order_status(order, "delivery_failed", %{
          failure_reason: "address_not_found",
          failure_notes: "Customer address could not be located"
        })

      # Should have created a staged refund
      refunds = Refunds.get_refunds_for_order(order.id)
      assert length(refunds) == 1

      refund = hd(refunds)
      assert refund.reason == "delivery_failed"
      assert Decimal.equal?(refund.amount, meal.price)
      assert refund.status == "pending"
      assert String.contains?(refund.reason_details, "address_not_found")
    end
  end
end
