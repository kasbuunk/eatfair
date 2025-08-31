defmodule Eatfair.Orders.DesiredEtaTest do
  use Eatfair.DataCase

  alias Eatfair.Orders

  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  describe "desired delivery time functionality" do
    setup do
      customer = user_fixture()
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      %{customer: customer, restaurant: restaurant, meal: meal}
    end

    test "order can be created with desired delivery time", %{
      customer: customer,
      restaurant: restaurant
    } do
      # 2 hours from now
      desired_time =
        NaiveDateTime.add(NaiveDateTime.utc_now(), 2 * 60 * 60) |> NaiveDateTime.truncate(:second)

      order_attrs = %{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        total_price: Decimal.new("25.00"),
        delivery_address: "Test Address 1, 1000 AA Amsterdam",
        desired_delivery_at: desired_time
      }

      {:ok, order} = Orders.create_order_with_items(order_attrs, [])

      assert order.desired_delivery_at == desired_time
      assert order.eta_accepted == false
      assert order.eta_pending == false
    end

    test "desired delivery time must be in the future", %{
      customer: customer,
      restaurant: restaurant
    } do
      # 30 minutes ago
      past_time = NaiveDateTime.add(NaiveDateTime.utc_now(), -30 * 60)

      order_attrs = %{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        total_price: Decimal.new("25.00"),
        delivery_address: "Test Address 1, 1000 AA Amsterdam",
        desired_delivery_at: past_time
      }

      {:error, changeset} = Orders.create_order_with_items(order_attrs, [])

      assert changeset.errors[:desired_delivery_at] != nil
      assert "must be in the future" in errors_on(changeset).desired_delivery_at
    end

    test "desired delivery time must be at least 30 minutes from now", %{
      customer: customer,
      restaurant: restaurant
    } do
      # 15 minutes from now
      too_soon = NaiveDateTime.add(NaiveDateTime.utc_now(), 15 * 60)

      order_attrs = %{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        total_price: Decimal.new("25.00"),
        delivery_address: "Test Address 1, 1000 AA Amsterdam",
        desired_delivery_at: too_soon
      }

      {:error, changeset} = Orders.create_order_with_items(order_attrs, [])

      assert changeset.errors[:desired_delivery_at] != nil
      assert "must be at least 30 minutes from now" in errors_on(changeset).desired_delivery_at
    end

    test "desired delivery time cannot be more than 3 days in future", %{
      customer: customer,
      restaurant: restaurant
    } do
      # 4 days from now
      too_far = NaiveDateTime.add(NaiveDateTime.utc_now(), 4 * 24 * 60 * 60)

      order_attrs = %{
        customer_id: customer.id,
        restaurant_id: restaurant.id,
        total_price: Decimal.new("25.00"),
        delivery_address: "Test Address 1, 1000 AA Amsterdam",
        desired_delivery_at: too_far
      }

      {:error, changeset} = Orders.create_order_with_items(order_attrs, [])

      assert changeset.errors[:desired_delivery_at] != nil
      assert "cannot be more than 3 days in advance" in errors_on(changeset).desired_delivery_at
    end

    test "restaurant can accept customer's desired ETA", %{
      customer: customer,
      restaurant: restaurant,
      meal: meal
    } do
      # 2 hours from now
      desired_time = NaiveDateTime.add(NaiveDateTime.utc_now(), 2 * 60 * 60)

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address 1, 1000 AA Amsterdam",
            desired_delivery_at: desired_time
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, updated_order} = Orders.accept_desired_eta(order)

      assert updated_order.eta_accepted == true
      assert updated_order.eta_pending == false
      assert updated_order.proposed_eta == nil
    end

    test "restaurant can propose alternative ETA", %{
      customer: customer,
      restaurant: restaurant,
      meal: meal
    } do
      # 2 hours from now
      desired_time =
        NaiveDateTime.add(NaiveDateTime.utc_now(), 2 * 60 * 60) |> NaiveDateTime.truncate(:second)

      # 3 hours from now
      proposed_time =
        NaiveDateTime.add(NaiveDateTime.utc_now(), 3 * 60 * 60) |> NaiveDateTime.truncate(:second)

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address 1, 1000 AA Amsterdam",
            desired_delivery_at: desired_time
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, updated_order} = Orders.propose_alternative_eta(order, proposed_time)

      assert updated_order.eta_accepted == false
      assert updated_order.eta_pending == true
      assert updated_order.proposed_eta == proposed_time
    end

    test "customer can accept restaurant's proposed ETA", %{
      customer: customer,
      restaurant: restaurant,
      meal: meal
    } do
      desired_time =
        NaiveDateTime.add(NaiveDateTime.utc_now(), 2 * 60 * 60) |> NaiveDateTime.truncate(:second)

      proposed_time =
        NaiveDateTime.add(NaiveDateTime.utc_now(), 3 * 60 * 60) |> NaiveDateTime.truncate(:second)

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Test Address 1, 1000 AA Amsterdam",
            desired_delivery_at: desired_time
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, order_with_proposal} = Orders.propose_alternative_eta(order, proposed_time)
      {:ok, final_order} = Orders.accept_proposed_eta(order_with_proposal)

      assert final_order.eta_accepted == true
      assert final_order.eta_pending == false
      assert final_order.desired_delivery_at == proposed_time
    end
  end
end
