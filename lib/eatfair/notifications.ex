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
