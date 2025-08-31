# Script to create sample notifications for Night Owl restaurant owner
# This helps demonstrate the notification experience on the dashboard

require Logger
alias Eatfair.{Notifications, Accounts}

# Find Night Owl owner
night_owl_email = "owner@nightowl.nl"

case Accounts.get_user_by_email(night_owl_email) do
  nil ->
    IO.puts("❌ Night Owl owner not found with email: #{night_owl_email}")

  owner ->
    IO.puts("🦉 Found Night Owl owner: #{owner.name}")

    # Create sample notification events based on valid event_types
    # Valid event types: "order_status_changed", "order_cancelled", "delivery_delayed",
    # "newsletter", "promotion", "system_announcement"
    sample_notifications = [
      %{
        event_type: "order_status_changed",
        priority: "high",
        data: %{
          "order_id" => 15874,
          "restaurant_name" => "Night Owl Express NL",
          "old_status" => "pending",
          "new_status" => "confirmed",
          "total_price" => "50.50",
          "delivery_address" => "123 Customer St, Amsterdam"
        }
      },
      %{
        event_type: "order_status_changed",
        priority: "normal",
        data: %{
          "order_id" => 15873,
          "restaurant_name" => "Night Owl Express NL",
          "old_status" => "confirmed",
          "new_status" => "preparing",
          "total_price" => "42.75",
          "delivery_address" => "456 Delivery Ave, Amsterdam"
        }
      },
      %{
        event_type: "order_status_changed",
        priority: "normal",
        data: %{
          "order_id" => 15872,
          "restaurant_name" => "Night Owl Express NL",
          "old_status" => "preparing",
          "new_status" => "ready",
          "total_price" => "38.50",
          "delivery_address" => "789 Pickup Rd, Amsterdam"
        }
      },
      %{
        event_type: "system_announcement",
        priority: "normal",
        data: %{
          "title" => "Restaurant Performance",
          "message" => "Your restaurant is performing exceptionally well tonight!",
          "action_url" => "/restaurant/analytics"
        }
      },
      %{
        event_type: "order_cancelled",
        priority: "high",
        data: %{
          "order_id" => 15875,
          "restaurant_name" => "Night Owl Express NL",
          "customer_name" => "Emma de Foodie",
          "total_price" => "49.50",
          "reason" => "Customer requested cancellation"
        }
      }
    ]

    IO.puts("📬 Creating #{length(sample_notifications)} sample notifications...")

    Enum.with_index(sample_notifications, 1)
    |> Enum.each(fn {notification_data, index} ->
      # Stagger notification times
      inserted_at = DateTime.utc_now() |> DateTime.add(-(index * 5), :minute)

      notification_attrs = %{
        # Use recipient_id instead of user_id
        recipient_id: owner.id,
        event_type: notification_data.event_type,
        priority: notification_data.priority,
        data: notification_data.data,
        # Set status explicitly
        status: "pending"
        # Note: Don't set inserted_at/updated_at manually as Ecto will handle those
      }

      case Notifications.create_event(notification_attrs) do
        {:ok, event} ->
          IO.puts("✅ Created #{notification_data.event_type} notification (ID: #{event.id})")

        {:error, changeset} ->
          IO.puts("❌ Failed to create notification: #{inspect(changeset.errors)}")
      end
    end)

    IO.puts("🎉 Sample notifications created for Night Owl owner!")
    IO.puts("🔔 Visit /restaurant/dashboard as owner@nightowl.nl to see notifications")
end
