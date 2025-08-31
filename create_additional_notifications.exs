# Script to create additional sample notifications to showcase all notification types
# This complements the main sample notifications script

require Logger
alias Eatfair.{Notifications, Accounts}

# Find Night Owl owner
night_owl_email = "owner@nightowl.nl"

case Accounts.get_user_by_email(night_owl_email) do
  nil ->
    IO.puts("❌ Night Owl owner not found with email: #{night_owl_email}")

  owner ->
    IO.puts("🦉 Found Night Owl owner: #{owner.name}")

    # Create additional notification types to showcase full range
    additional_notifications = [
      %{
        event_type: "delivery_delayed",
        priority: "high",
        data: %{
          "order_id" => 15876,
          "restaurant_name" => "Night Owl Express NL",
          "delay_reason" => "Heavy traffic in the area",
          "estimated_delay_minutes" => 15,
          "new_estimated_delivery" => "22:45",
          "total_price" => "35.25",
          "customer_phone" => "+31 6 1234 5678"
        }
      },
      %{
        event_type: "promotion",
        priority: "low",
        data: %{
          "title" => "Weekend Special Available",
          "message" =>
            "Your weekend discount promotion is now active! Customers can enjoy 15% off orders above €30.",
          "promo_code" => "WEEKEND15",
          "valid_until" => "2024-08-25 23:59:59",
          "action_url" => "/restaurant/promotions"
        }
      },
      %{
        event_type: "newsletter",
        priority: "low",
        data: %{
          "title" => "EatFair Monthly Newsletter",
          "message" =>
            "Check out this month's platform updates and new features for restaurant partners.",
          "newsletter_url" => "/newsletter/august-2024",
          "featured_topics" => [
            "New analytics dashboard",
            "Improved delivery tracking",
            "Customer loyalty features"
          ]
        }
      }
    ]

    IO.puts("📬 Creating #{length(additional_notifications)} additional notifications...")

    Enum.with_index(additional_notifications, 1)
    |> Enum.each(fn {notification_data, index} ->
      notification_attrs = %{
        recipient_id: owner.id,
        event_type: notification_data.event_type,
        priority: notification_data.priority,
        data: notification_data.data,
        status: "pending"
      }

      case Notifications.create_event(notification_attrs) do
        {:ok, event} ->
          IO.puts("✅ Created #{notification_data.event_type} notification (ID: #{event.id})")

        {:error, changeset} ->
          IO.puts("❌ Failed to create notification: #{inspect(changeset.errors)}")
      end
    end)

    IO.puts("🎉 Additional sample notifications created!")

    IO.puts(
      "🔔 Night Owl owner should now see #{length(additional_notifications) + 5} total notifications"
    )
end
