defmodule EatfairWeb.RestaurantOrderProcessingTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  alias Eatfair.Orders
  alias Eatfair.Notifications

  describe "🏪 Restaurant Order Processing: Missing Critical Features" do
    test "restaurant owner can see pending orders and accept them", %{conn: conn} do
      # 🎯 Setup: Restaurant receives a new order in pending state  
      customer = user_fixture()
      restaurant_owner = user_fixture()
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      # Create order in pending status (not auto-confirmed)
      {:ok, pending_order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "123 Customer St, Amsterdam",
            customer_phone: "+31612345678",
            customer_email: "customer@example.com",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 2}]
        )

      conn = log_in_user(conn, restaurant_owner)

      # 🏪 Restaurant owner visits order dashboard
      {:ok, dashboard_live, html} = live(conn, "/restaurant/orders")

      # ✅ Should see pending order in "Pending Orders" section  
      assert html =~ "Pending Orders"
      assert html =~ "123 Customer St, Amsterdam"
      assert html =~ pending_order.customer_phone
      assert html =~ pending_order.customer_email

      # ✅ Should have Accept Order button
      assert has_element?(dashboard_live, "#accept-order-#{pending_order.id}")
      
      # 👨‍🍳 Restaurant owner accepts the order
      dashboard_live
      |> element("#accept-order-#{pending_order.id}")
      |> render_click()

      # ✅ Order should move to confirmed status
      updated_order = Orders.get_order!(pending_order.id)
      assert updated_order.status == "confirmed"
      assert updated_order.confirmed_at != nil

      # ✅ Should no longer see order in Pending section
      html = render(dashboard_live)
      refute html =~ "<h2 class=\"text-xl font-bold text-gray-900 mb-4\">Pending Orders</h2>"
      
      # ✅ Should see order in "New Orders" (confirmed) section
      assert html =~ "New Orders"
      assert html =~ "123 Customer St, Amsterdam"
    end

    test "restaurant owner can reject pending orders with reason", %{conn: conn} do
      # 🎯 Setup: Restaurant receives an order they cannot fulfill
      customer = user_fixture()
      restaurant_owner = user_fixture()
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, pending_order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "456 Customer Ave, Utrecht",
            customer_phone: "+31687654321", 
            customer_email: "customer2@example.com",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 3}]
        )

      conn = log_in_user(conn, restaurant_owner)
      {:ok, dashboard_live, _html} = live(conn, "/restaurant/orders")

      # ✅ Should have Reject Order button
      assert has_element?(dashboard_live, "#reject-order-#{pending_order.id}")

      # 👨‍🍳 Restaurant owner rejects the order
      dashboard_live
      |> element("#reject-order-#{pending_order.id}")  
      |> render_click()

      # ✅ Should show rejection reason modal/form
      assert has_element?(dashboard_live, "[data-modal='rejection-modal']")
      
      # 👨‍🍳 Enter rejection reason
      dashboard_live
      |> form("#rejection-form", %{
        "rejection_reason" => "out_of_ingredients",
        "rejection_notes" => "Sorry, we ran out of the main ingredient for this dish"
      })
      |> render_submit()

      # ✅ Order should move to cancelled status  
      updated_order = Orders.get_order!(pending_order.id)
      assert updated_order.status == "cancelled"
      assert updated_order.cancelled_at != nil

      # ✅ Should create high-priority notification for customer
      events = Notifications.list_events_for_user(customer.id)
      rejection_event = Enum.find(events, &(&1.data["new_status"] == "cancelled"))
      assert rejection_event != nil
      assert rejection_event.priority == "high"
      assert rejection_event.data["rejection_reason"] == "out_of_ingredients"
      assert rejection_event.data["rejection_notes"] == "Sorry, we ran out of the main ingredient for this dish"

      # ✅ Order should no longer appear on restaurant dashboard
      html = render(dashboard_live)
      refute html =~ "456 Customer Ave, Utrecht"
    end

    test "restaurant owner can handle delivery failures", %{conn: conn} do
      # 🎯 Setup: Order is out for delivery but encounters a problem
      customer = user_fixture()
      restaurant_owner = user_fixture()
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, delivery_order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "789 Delivery St, Rotterdam",
            customer_phone: "+31656789123",
            status: "out_for_delivery"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      conn = log_in_user(conn, restaurant_owner)
      {:ok, dashboard_live, html} = live(conn, "/restaurant/orders")

      # ✅ Should see order in "Out for Delivery" section
      assert html =~ "Out for Delivery"
      assert html =~ "789 Delivery St, Rotterdam"

      # ✅ Should have "Report Delivery Problem" button
      assert has_element?(dashboard_live, "#report-delivery-failure-#{delivery_order.id}")

      # 👨‍🍳 Restaurant reports delivery failure
      dashboard_live
      |> element("#report-delivery-failure-#{delivery_order.id}")
      |> render_click()

      # ✅ Should show failure reason form
      assert has_element?(dashboard_live, "[data-modal='delivery-failure-modal']")

      # 👨‍🍳 Enter failure details
      dashboard_live
      |> form("#delivery-failure-form", %{
        "failure_reason" => "address_not_found",
        "failure_notes" => "Courier unable to locate the address, customer not answering phone"
      })
      |> render_submit()

      # ✅ Order should move to delivery_failed status
      updated_order = Orders.get_order!(delivery_order.id)
      assert updated_order.status == "delivery_failed"

      # ✅ Should create high-priority notification for customer
      events = Notifications.list_events_for_user(customer.id)
      failure_event = Enum.find(events, &(&1.data["new_status"] == "delivery_failed"))
      assert failure_event != nil
      assert failure_event.priority == "high"
      assert failure_event.data["failure_reason"] == "address_not_found"
    end

    test "restaurant owner can see customer contact information and use contact links", %{conn: conn} do
      # 🎯 Setup: Order with customer contact details
      customer = user_fixture()
      restaurant_owner = user_fixture()
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, _order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "321 Contact Test St, Den Haag",
            customer_phone: "+31698765432",
            customer_email: "contact@example.com", 
            status: "confirmed"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      conn = log_in_user(conn, restaurant_owner)
      {:ok, dashboard_live, html} = live(conn, "/restaurant/orders")

      # ✅ Should display customer contact information
      assert html =~ "+31698765432"
      assert html =~ "contact@example.com"

      # ✅ Should have clickable phone link
      assert html =~ "tel:+31698765432"
      
      # ✅ Should have clickable email link  
      assert html =~ "mailto:contact@example.com"

      # ✅ Phone and email should be easily accessible for direct communication
      assert has_element?(dashboard_live, "[data-contact='phone'][href*='+31698765432']")
      assert has_element?(dashboard_live, "[data-contact='email'][href*='contact@example.com']")
    end

    test "pending orders are included in restaurant order listing", %{conn: _conn} do
      # 🎯 Test that Orders.list_restaurant_orders includes pending orders  
      restaurant = restaurant_fixture()
      customer = user_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      # Create orders in different statuses
      {:ok, pending_order} = 
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Pending Order Address",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, confirmed_order} = 
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Confirmed Order Address", 
            status: "confirmed"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # ✅ list_restaurant_orders should include pending orders
      orders_by_status = Orders.list_restaurant_orders(restaurant.id)
      
      # Should have pending key with pending orders
      assert Map.has_key?(orders_by_status, :pending)
      assert length(orders_by_status.pending) == 1
      assert hd(orders_by_status.pending).id == pending_order.id
      
      # Should still have confirmed orders
      assert length(orders_by_status.confirmed) == 1
      assert hd(orders_by_status.confirmed).id == confirmed_order.id
    end

    test "delivery_failed is valid order status with proper transitions", %{conn: _conn} do
      # 🎯 Test that delivery_failed status works in the order system
      customer = user_fixture()
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Failure Test Address",
            status: "out_for_delivery"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # ✅ Should be able to transition from out_for_delivery to delivery_failed
      {:ok, failed_order} = Orders.update_order_status(order, "delivery_failed", %{
        delay_reason: "Could not locate customer address"
      })

      assert failed_order.status == "delivery_failed"
      assert failed_order.delay_reason == "Could not locate customer address"

      # ✅ Should create notification
      events = Notifications.list_events_for_user(customer.id)
      failure_event = Enum.find(events, &(&1.data["new_status"] == "delivery_failed"))
      assert failure_event != nil
      assert failure_event.priority == "high"
    end
  end
end
