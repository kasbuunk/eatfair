defmodule Eatfair.Notifications do
  @moduledoc """
  The Notifications context.

  This module handles all notification logic and provides an extensible system for:
  - Order status notifications
  - Newsletter subscriptions  
  - Promotional campaigns
  - System announcements
  - SMS, Email, Push notifications (when configured)

  The system is designed to be decoupled from specific delivery channels,
  allowing easy integration with external services while maintaining
  comprehensive internal logging and preferences management.
  """

  import Ecto.Query, warn: false
  alias Eatfair.Repo
  alias Eatfair.Notifications.{Event, UserPreference}

  @doc """
  Records a notification event without sending.

  This allows the system to track what notifications should be sent
  while keeping delivery channel integration separate.
  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets user notification preferences with defaults.
  """
  def get_user_preferences(user_id) do
    case Repo.get_by(UserPreference, user_id: user_id) do
      nil -> create_default_preferences(user_id)
      preferences -> {:ok, preferences}
    end
  end

  @doc """
  Creates notification event for order status change.

  This is the main integration point with the order tracking system.
  Enhanced to support donation-aware delivery notifications.
  """
  def notify_order_status_change(order, old_status, new_status, context \\ %{}) do
    event_data =
      %{
        order_id: order.id,
        restaurant_name: order.restaurant.name,
        old_status: old_status,
        new_status: new_status,
        delivery_address: order.delivery_address,
        total_price: order.total_price
      }
      |> Map.merge(context)
      |> maybe_add_donation_aware_data(order, new_status)
      |> sanitize_event_data()

    with {:ok, event} <-
           create_event(%{
             event_type: "order_status_changed",
             recipient_id: order.customer_id,
             data: event_data,
             priority: priority_for_status(new_status)
           }) do
      # In production, this would trigger actual notifications
      # based on user preferences and configured channels
      broadcast_event(event)
      {:ok, event}
    end
  end

  @doc """
  Broadcasts notification event via PubSub for real-time updates.
  """
  def broadcast_event(event) do
    Phoenix.PubSub.broadcast(
      Eatfair.PubSub,
      "user_notifications:#{event.recipient_id}",
      {:notification_event, event}
    )

    Phoenix.PubSub.broadcast(
      Eatfair.PubSub,
      "notification_events",
      {:notification_event, event}
    )
  end

  # Private functions

  defp create_default_preferences(user_id) do
    attrs = %{
      user_id: user_id,
      email_enabled: true,
      sms_enabled: false,
      push_enabled: true,
      order_status_notifications: true,
      marketing_notifications: false,
      newsletter_enabled: false
    }

    %UserPreference{}
    |> UserPreference.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists notification events for a user.
  """
  def list_events_for_user(user_id) do
    Event
    |> where([e], e.recipient_id == ^user_id)
    |> order_by([e], desc: e.inserted_at)
    |> Repo.all()
  end

  @doc """
  Updates user notification preferences.
  """
  def update_user_preferences(user_id, attrs) do
    case Repo.get_by(UserPreference, user_id: user_id) do
      nil ->
        %UserPreference{}
        |> UserPreference.changeset(Map.put(attrs, :user_id, user_id))
        |> Repo.insert()

      preferences ->
        preferences
        |> UserPreference.changeset(attrs)
        |> Repo.update()
    end
  end

  # Sanitizes event data to ensure all values can be serialized to JSON.
  # Specifically handles Decimal types by converting them to strings,
  # preventing Ecto.ChangeError when storing notification data.
  defp sanitize_event_data(%Decimal{} = decimal) do
    Decimal.to_string(decimal)
  end

  defp sanitize_event_data(data) when is_struct(data) do
    # Handle other structs (like NaiveDateTime) by leaving them as-is
    # since they are typically JSON-serializable
    data
  end

  defp sanitize_event_data(data) when is_map(data) do
    Map.new(data, fn {key, value} -> {key, sanitize_event_data(value)} end)
  end

  defp sanitize_event_data(data) when is_list(data) do
    Enum.map(data, &sanitize_event_data/1)
  end

  defp sanitize_event_data(data), do: data

  # Enhanced donation-aware notification data generation
  defp maybe_add_donation_aware_data(event_data, order, "delivered") do
    donation_amount = order.donation_amount || Decimal.new("0.00")
    has_donation = Decimal.gt?(donation_amount, 0)

    base_donation_data = %{
      "donation_amount" => Decimal.to_string(donation_amount),
      "support_options" => ["social_sharing", "write_reviews"]
    }

    donation_specific_data =
      if has_donation do
        # Customer donated - thank them and encourage sharing
        %{
          "message_type" => "thank_you",
          "message_tone" => "grateful",
          "social_share_url" => generate_social_share_url(order),
          "social_message" => "I just supported local food delivery through Eatfair!"
        }
      else
        # No donation - kind request for support
        %{
          "message_type" => "support_request",
          "message_tone" => "kind_request",
          "donation_url" => generate_donation_url(order),
          "donation_amounts" => ["1.00", "2.50", "5.00"],
          "support_options" => ["social_sharing", "write_reviews", "recommend_platform"]
        }
      end

    event_data
    |> Map.merge(base_donation_data)
    |> Map.merge(donation_specific_data)
  end

  defp maybe_add_donation_aware_data(event_data, _order, _status), do: event_data

  defp generate_social_share_url(order) do
    # Generate a social sharing URL - in production this would be a real URL
    "https://eatfair.com/share/order/#{order.id}"
  end

  defp generate_donation_url(order) do
    # Generate a donation URL - in production this would be a real donation flow
    "https://eatfair.com/donate/restaurant/#{order.restaurant_id}"
  end

  defp priority_for_status("confirmed"), do: "normal"
  defp priority_for_status("preparing"), do: "normal"
  defp priority_for_status("ready"), do: "high"
  defp priority_for_status("out_for_delivery"), do: "high"
  defp priority_for_status("delivered"), do: "normal"
  defp priority_for_status("cancelled"), do: "high"
  defp priority_for_status("rejected"), do: "high"
  defp priority_for_status("delivery_failed"), do: "high"
  defp priority_for_status(_), do: "low"
end
