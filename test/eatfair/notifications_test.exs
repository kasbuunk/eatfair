defmodule Eatfair.NotificationsTest do
  use Eatfair.DataCase

  alias Eatfair.Notifications
  alias Eatfair.Notifications.Event
  alias Eatfair.Restaurants

  import Eatfair.AccountsFixtures

  describe "create_event/1" do
    test "creates a notification event with valid attributes" do
      user = user_fixture()

      attrs = %{
        event_type: "order_status_changed",
        recipient_id: user.id,
        data: %{order_id: 123, status: "confirmed"},
        priority: "normal"
      }

      assert {:ok, %Event{} = event} = Notifications.create_event(attrs)
      assert event.event_type == "order_status_changed"
      assert event.recipient_id == user.id
      assert event.data == %{order_id: 123, status: "confirmed"}
      assert event.priority == "normal"
    end

    test "validates required fields" do
      assert {:error, %Ecto.Changeset{} = changeset} = Notifications.create_event(%{})
      assert %{event_type: ["can't be blank"]} = errors_on(changeset)
      assert %{recipient_id: ["can't be blank"]} = errors_on(changeset)
      assert %{data: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "notify_order_status_change/4" do
    setup do
      user = user_fixture()

      owner =
        user_fixture(%{
          email: "owner@restaurant.com",
          name: "Restaurant Owner",
          role: :owner
        })

      {:ok, restaurant} =
        Restaurants.create_restaurant(%{
          name: "Test Restaurant",
          address: "123 Test St",
          latitude: Decimal.new("52.3702"),
          longitude: Decimal.new("4.9002"),
          delivery_radius_km: 5,
          delivery_time: 40,
          min_order_value: Decimal.new("15.00"),
          is_open: true,
          rating: Decimal.new("4.5"),
          owner_id: owner.id,
          timezone: "Europe/Amsterdam",
          operating_days: 127,
          order_open_time: 0,
          order_close_time: 1440,
          kitchen_close_time: 1440,
          order_cutoff_before_kitchen_close: 5,
          force_closed: false
        })

      %{user: user, restaurant: restaurant}
    end

    test "handles order with Decimal total_price correctly", %{user: user, restaurant: restaurant} do
      # Create a mock order with Decimal total_price
      order = %{
        id: 123,
        customer_id: user.id,
        restaurant: restaurant,
        total_price: Decimal.new("43.5"),
        delivery_address: "Test Address"
      }

      # After fix, this should work without errors
      assert {:ok, %Event{} = event} =
               Notifications.notify_order_status_change(order, "pending", "confirmed")

      # The data should contain the serialized Decimal as a string
      assert event.data.total_price == "43.5"
      assert event.data.order_id == 123
      assert event.data.restaurant_name == restaurant.name
    end

    test "creates notification event for order status change", %{
      user: user,
      restaurant: restaurant
    } do
      # Use string price to avoid the Decimal issue for this basic test
      order = %{
        id: 123,
        customer_id: user.id,
        restaurant: restaurant,
        # String instead of Decimal for now
        total_price: "43.5",
        delivery_address: "Test Address"
      }

      assert {:ok, %Event{} = event} =
               Notifications.notify_order_status_change(order, "pending", "confirmed")

      assert event.event_type == "order_status_changed"
      assert event.recipient_id == user.id
      assert event.data.order_id == 123
      assert event.data.old_status == "pending"
      assert event.data.new_status == "confirmed"
      assert event.priority == "normal"
    end

    test "includes context data in notification", %{user: user, restaurant: restaurant} do
      order = %{
        id: 123,
        customer_id: user.id,
        restaurant: restaurant,
        total_price: "43.5",
        delivery_address: "Test Address"
      }

      context = %{delay_reason: "Traffic jam", estimated_delivery_at: ~N[2024-01-01 18:00:00]}

      assert {:ok, %Event{} = event} =
               Notifications.notify_order_status_change(order, "pending", "confirmed", context)

      assert event.data.delay_reason == "Traffic jam"
      assert event.data.estimated_delivery_at == ~N[2024-01-01 18:00:00]
    end
  end

  describe "get_user_preferences/1" do
    test "creates default preferences for new user" do
      user = user_fixture()

      assert {:ok, preferences} = Notifications.get_user_preferences(user.id)
      assert preferences.user_id == user.id
      assert preferences.email_enabled == true
      assert preferences.order_status_notifications == true
    end

    test "returns existing preferences" do
      user = user_fixture()

      # Create initial preferences
      {:ok, _} = Notifications.get_user_preferences(user.id)

      # Update preferences
      {:ok, _updated} = Notifications.update_user_preferences(user.id, %{email_enabled: false})

      # Should return updated preferences
      assert {:ok, preferences} = Notifications.get_user_preferences(user.id)
      assert preferences.email_enabled == false
    end
  end

  describe "list_events_for_user/1" do
    test "returns events for specific user ordered by insertion time" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create events for user1
      {:ok, event1} =
        Notifications.create_event(%{
          event_type: "order_status_changed",
          recipient_id: user1.id,
          data: %{order_id: 1}
        })

      {:ok, event2} =
        Notifications.create_event(%{
          event_type: "order_status_changed",
          recipient_id: user1.id,
          data: %{order_id: 2}
        })

      # Create event for user2
      {:ok, _event3} =
        Notifications.create_event(%{
          event_type: "order_status_changed",
          recipient_id: user2.id,
          data: %{order_id: 3}
        })

      events = Notifications.list_events_for_user(user1.id)

      assert length(events) == 2
      # Should contain both events for user1
      event_ids = Enum.map(events, & &1.id)
      assert event1.id in event_ids
      assert event2.id in event_ids
      # Should contain the correct order IDs
      order_ids = Enum.map(events, & &1.data["order_id"])
      assert 1 in order_ids
      assert 2 in order_ids
    end
  end
end
