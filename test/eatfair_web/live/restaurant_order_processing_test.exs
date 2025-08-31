defmodule EatfairWeb.RestaurantOrderProcessingTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  alias Eatfair.Orders
  alias Eatfair.Notifications

  describe "🧭 Restaurant Navigation: Critical Bug - Missing Navbar" do
    test "restaurant orders page must have navbar for navigation", %{conn: conn} do
      # 🎯 Setup: Restaurant owner accessing order management
      restaurant_owner = user_fixture(%{role: "restaurant_owner"})
      _restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      
      conn = log_in_user(conn, restaurant_owner)
      
      # 🏪 Restaurant owner visits order management page
      {:ok, orders_live, html} = live(conn, "/restaurant/orders")
      
      # ✅ Must have navbar with navigation links
      assert has_element?(orders_live, "nav", "Navigation bar")
      assert has_element?(orders_live, "a[href='/restaurant/dashboard']", "My Restaurant")
      assert has_element?(orders_live, "a[href='/']", "Eatfair")
      
      # ✅ Navbar should be part of main layout, not just order page
      assert html =~ "nav"
      # Check for typical navbar content
      assert html =~ "Eatfair" || html =~ "My Restaurant" || html =~ "Track Orders"
      
      # ✅ Navigation links should be functional
      # Test clicking dashboard link takes user to dashboard (select desktop version)
      result = orders_live |> element(".hidden.md\\:flex a[href='/restaurant/dashboard']") |> render_click()
      
      # Should redirect or navigate to dashboard
      case result do
        {:error, {:redirect, %{to: "/restaurant/dashboard"}}} -> 
          # Good - proper redirect
          assert true
        {:error, {:live_redirect, %{to: "/restaurant/dashboard"}}} ->
          # Also good - live redirect  
          assert true
        _ ->
          # Should at least have redirect behavior
          assert false, "Dashboard navigation should redirect to /restaurant/dashboard"
      end
    end
  end

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

      assert rejection_event.data["rejection_notes"] ==
               "Sorry, we ran out of the main ingredient for this dish"

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

    test "restaurant owner can see customer contact information and use contact links", %{
      conn: conn
    } do
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
      {:ok, failed_order} =
        Orders.update_order_status(order, "delivery_failed", %{
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

  describe "📊 Historic Orders: Missing Critical Feature" do
    test "restaurant owner can view completed order history", %{conn: conn} do
      # 🎯 Setup: Restaurant with mix of active and historic orders
      restaurant_owner = user_fixture(%{role: "restaurant_owner"})
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      customer = user_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      # Create active orders
      {:ok, _active_order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Active Order Address",
            status: "confirmed"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # Create historic orders
      {:ok, _delivered_order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Delivered Order Address",
            status: "delivered"
          },
          [%{meal_id: meal.id, quantity: 2}]
        )

      {:ok, _cancelled_order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Cancelled Order Address",
            status: "cancelled"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      conn = log_in_user(conn, restaurant_owner)

      # 🏪 Restaurant owner visits order management page
      {:ok, orders_live, html} = live(conn, "/restaurant/orders")

      # ✅ Should see "Active" tab by default
      assert html =~ "Active"
      assert html =~ "Active Order Address"
      refute html =~ "Delivered Order Address"
      refute html =~ "Cancelled Order Address"

      # ✅ Should have "History" tab button
      assert has_element?(orders_live, "[data-test='history-tab']", "History")

      # 👨‍🍳 Restaurant owner clicks History tab
      orders_live
      |> element("[data-test='history-tab']")
      |> render_click()

      # ✅ Should now see historic orders
      html = render(orders_live)
      refute html =~ "Active Order Address"  # Active orders hidden
      assert html =~ "Delivered Order Address"
      assert html =~ "Cancelled Order Address"
      assert html =~ "Delivered"
      assert html =~ "cancelled"

      # ✅ Should be able to switch back to Active tab
      assert has_element?(orders_live, "[data-test='active-tab']", "Active")

      orders_live
      |> element("[data-test='active-tab']")
      |> render_click()

      html = render(orders_live)
      assert html =~ "Active Order Address"
      refute html =~ "Delivered Order Address"
      refute html =~ "Cancelled Order Address"
    end

    test "Orders.list_restaurant_orders/2 supports active vs history filtering", %{conn: _conn} do
      # 🎯 Test the context function directly
      restaurant = restaurant_fixture()
      customer = user_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      # Create orders in different statuses
      {:ok, _pending} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Pending Address",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, _confirmed} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Confirmed Address",
            status: "confirmed"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, _delivered} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Delivered Address",
            status: "delivered"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      {:ok, _cancelled} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Cancelled Address",
            status: "cancelled"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      # ✅ Active filter should return active statuses only
      active_orders = Orders.list_restaurant_orders(restaurant.id, :active)
      active_addresses = extract_addresses(active_orders)
      assert "Pending Address" in active_addresses
      assert "Confirmed Address" in active_addresses
      refute "Delivered Address" in active_addresses
      refute "Cancelled Address" in active_addresses

      # ✅ History filter should return completed statuses only  
      history_orders = Orders.list_restaurant_orders(restaurant.id, :history)
      history_addresses = extract_addresses(history_orders)
      refute "Pending Address" in history_addresses
      refute "Confirmed Address" in history_addresses
      assert "Delivered Address" in history_addresses
      assert "Cancelled Address" in history_addresses

      # ✅ Default (no filter) should return all active orders for backward compatibility
      all_active_orders = Orders.list_restaurant_orders(restaurant.id)
      all_addresses = extract_addresses(all_active_orders)
      assert "Pending Address" in all_addresses
      assert "Confirmed Address" in all_addresses
      refute "Delivered Address" in all_addresses
      refute "Cancelled Address" in all_addresses
    end

    defp extract_addresses(orders_by_status) when is_map(orders_by_status) do
      orders_by_status
      |> Map.values()
      |> List.flatten()
      |> Enum.map(& &1.delivery_address)
    end

    defp extract_addresses(orders) when is_list(orders) do
      Enum.map(orders, & &1.delivery_address)
    end
  end

  describe "🚚 Courier Integration: Missing Critical Features" do
    test "Night Owl couriers can login and access delivery dashboard", %{conn: conn} do
      # 🎯 Setup: Test specific Night Owl couriers from seeds
      max_courier = user_fixture(%{
        email: "max.speedman@courier.nightowl.nl",
        name: "Max Speedman", 
        role: "courier",
        phone_number: "+31612345001"
      })
      
      _lisa_courier = user_fixture(%{
        email: "lisa.lightning@courier.nightowl.nl", 
        name: "Lisa Lightning",
        role: "courier",
        phone_number: "+31612345002" 
      })

      # 🚚 Max courier logs in and accesses dashboard
      conn = log_in_user(conn, max_courier)
      
      # ✅ Should be able to access courier dashboard
      {:ok, courier_live, html} = live(conn, "/courier/dashboard")
      
      assert html =~ "Courier Dashboard"
      assert html =~ "Max Speedman"  # Courier name displayed
      assert html =~ "Available Delivery Batches"  # Core courier functionality
      
      # ✅ Should have logout functionality
      assert has_element?(courier_live, "[data-test='logout-link']", "Log out")
    end

    test "courier role authorization prevents non-couriers from accessing courier dashboard", %{conn: conn} do
      # 🎯 Setup: Regular customer tries to access courier dashboard
      customer = user_fixture(%{role: "customer"})
      conn = log_in_user(conn, customer)
      
      # ❌ Should be redirected and see error message
      {:error, {:redirect, %{to: redirect_path, flash: %{"error" => error_message}}}} = 
        live(conn, "/courier/dashboard")
      
      assert redirect_path == "/courier/login"
      assert error_message =~ "You must be a courier"
    end
    
    test "restaurant owners cannot access courier features", %{conn: conn} do
      # 🎯 Setup: Restaurant owner tries courier access
      restaurant_owner = user_fixture(%{role: "restaurant_owner"})
      conn = log_in_user(conn, restaurant_owner)
      
      # ❌ Should be denied access
      {:error, {:redirect, %{to: redirect_path, flash: %{"error" => error_message}}}} = 
        live(conn, "/courier/dashboard")
      
      assert redirect_path == "/courier/login" 
      assert error_message =~ "You must be a courier"
    end
  end
end
