defmodule EatfairWeb.NotificationSystemTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  alias Eatfair.{Orders, Notifications}

  # MVP: Notification center is hidden for now, so these tests are temporarily disabled
  @moduletag :skip

  describe "🔔 Real-time Notification System" do
    test "restaurant owner sees real-time notifications for order updates", %{conn: conn} do
      # Setup: Restaurant owner with orders
      restaurant_owner = user_fixture()
      customer = user_fixture()
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "123 Notification Test St",
            status: "pending"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      conn = log_in_user(conn, restaurant_owner)

      # Restaurant owner visits order management dashboard
      {:ok, management_live, html} = live(conn, "/restaurant/orders")

      # Should see notification display component
      assert has_element?(management_live, "[data-testid='notification-center']")

      # Should initially have no notifications displayed
      refute html =~ "notification-item"

      # Simulate order status change that triggers notification
      {:ok, _updated_order} = Orders.update_order_status(order, "confirmed")

      # Wait for live view to process real-time notification
      :timer.sleep(50)

      # Should now see notification appear
      html = render(management_live)
      assert html =~ "Order ##{order.id}"
      assert html =~ "confirmed"
      assert has_element?(management_live, "[data-testid='notification-item']")
    end

    test "notifications can be dismissed by user", %{conn: conn} do
      # Setup
      restaurant_owner = user_fixture()
      _customer = user_fixture()
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      _meal = meal_fixture(%{restaurant_id: restaurant.id})

      # Create notification event manually to test UI
      {:ok, _event} =
        Notifications.create_event(%{
          event_type: "order_status_changed",
          recipient_id: restaurant_owner.id,
          priority: "high",
          data: %{
            order_id: 999,
            restaurant_name: restaurant.name,
            old_status: "pending",
            new_status: "cancelled",
            rejection_reason: "out_of_stock"
          }
        })

      conn = log_in_user(conn, restaurant_owner)
      {:ok, management_live, html} = live(conn, "/restaurant/orders")

      # Should see the notification
      assert html =~ "Order #999"
      assert html =~ "cancelled"
      assert has_element?(management_live, "[data-testid='notification-item']")

      # Click dismiss button
      management_live
      |> element("[data-testid='dismiss-notification']")
      |> render_click()

      # Notification should be hidden/removed
      html = render(management_live)
      refute html =~ "Order #999"
      refute has_element?(management_live, "[data-testid='notification-item']")
    end

    test "notifications have correct priority styling", %{conn: conn} do
      restaurant_owner = user_fixture()
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})

      # Create high priority notification
      {:ok, _high_event} =
        Notifications.create_event(%{
          event_type: "order_status_changed",
          recipient_id: restaurant_owner.id,
          priority: "high",
          data: %{
            order_id: 1,
            restaurant_name: restaurant.name,
            new_status: "cancelled",
            rejection_reason: "emergency_closure"
          }
        })

      # Create normal priority notification  
      {:ok, _normal_event} =
        Notifications.create_event(%{
          event_type: "order_status_changed",
          recipient_id: restaurant_owner.id,
          priority: "normal",
          data: %{
            order_id: 2,
            restaurant_name: restaurant.name,
            new_status: "confirmed"
          }
        })

      conn = log_in_user(conn, restaurant_owner)
      {:ok, management_live, html} = live(conn, "/restaurant/orders")

      # Should see both notifications with different styling
      assert html =~ "Order #1"
      assert html =~ "Order #2"

      # High priority notification should have urgent styling
      assert has_element?(management_live, "[data-priority='high']")
      assert has_element?(management_live, "[data-priority='normal']")
    end

    test "notification center shows unread count", %{conn: conn} do
      restaurant_owner = user_fixture()
      _restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})

      # Create multiple notifications
      {:ok, _event1} =
        Notifications.create_event(%{
          event_type: "order_status_changed",
          recipient_id: restaurant_owner.id,
          priority: "normal",
          data: %{order_id: 1, new_status: "confirmed"}
        })

      {:ok, _event2} =
        Notifications.create_event(%{
          event_type: "order_status_changed",
          recipient_id: restaurant_owner.id,
          priority: "high",
          data: %{order_id: 2, new_status: "cancelled"}
        })

      conn = log_in_user(conn, restaurant_owner)
      {:ok, management_live, html} = live(conn, "/restaurant/orders")

      # Should show unread count badge
      assert html =~ "notification-count"
      # Two unread notifications
      assert html =~ "2"
      assert has_element?(management_live, "[data-testid='notification-count']")
    end

    test "notifications auto-hide after a delay for non-critical events", %{conn: conn} do
      restaurant_owner = user_fixture()
      customer = user_fixture()
      restaurant = restaurant_fixture(%{owner_id: restaurant_owner.id})
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_order_with_items(
          %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            total_price: meal.price,
            delivery_address: "Auto Hide Test Address",
            status: "preparing"
          },
          [%{meal_id: meal.id, quantity: 1}]
        )

      conn = log_in_user(conn, restaurant_owner)
      {:ok, management_live, _html} = live(conn, "/restaurant/orders")

      # Trigger normal priority notification (order ready)
      {:ok, _updated_order} = Orders.update_order_status(order, "ready")

      # Wait for notification to appear
      :timer.sleep(50)
      html = render(management_live)
      assert html =~ "ready"
      assert has_element?(management_live, "[data-testid='notification-item']")

      # For this test, we'll just verify the notification has auto-hide attribute
      # In real implementation, it would automatically disappear after timer
      assert has_element?(management_live, "[data-auto-hide='true']")
    end
  end
end
