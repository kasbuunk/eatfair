defmodule EatfairWeb.RestaurantLive.Dashboard do
  @moduledoc """
  Restaurant dashboard for daily operations management.

  Empowers restaurant owners with simple, powerful tools to manage their business.
  Implements the project specification: "Restaurant owners retain 100% of their revenue
  while maintaining control over their customer relationships"
  """

  use EatfairWeb, :live_view

  alias Eatfair.Restaurants
  alias Eatfair.Orders
  alias Eatfair.Notifications
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    case Restaurants.get_user_restaurant(user.id) do
      nil ->
        # No restaurant - guide to onboarding
        {:ok, redirect(socket, to: ~p"/restaurant/onboard")}

      restaurant ->
        # Restaurant owner - show dashboard
        # Subscribe to real-time order updates and notifications
        PubSub.subscribe(Eatfair.PubSub, "restaurant_orders:#{restaurant.id}")
        PubSub.subscribe(Eatfair.PubSub, "user_notifications:#{user.id}")

        # Load order counts for at-a-glance order management
        pending_count = Orders.count_pending_confirmations(restaurant.id)
        active_count = Orders.count_active_orders(restaurant.id)

        # Load recent notifications for the user
        notification_events = Notifications.list_events_for_user(user.id) |> Enum.take(5)
        notifications = Enum.map(notification_events, &convert_event_to_notification/1)
        unread_count = Enum.count(notifications, &(!&1.read))

        socket =
          socket
          |> assign(:restaurant, restaurant)
          |> assign(:page_title, "#{restaurant.name} - Dashboard")
          |> assign(:pending_count, pending_count)
          |> assign(:active_count, active_count)
          |> assign(:last_updated, DateTime.utc_now())
          |> assign(:connection_status, :connected)
          |> assign(:notifications, notifications)
          |> assign(:unread_count, unread_count)
          |> assign(:show_notification_center, false)

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("toggle_status", _params, socket) do
    restaurant = socket.assigns.restaurant
    new_status = !restaurant.is_open

    case Restaurants.update_restaurant(restaurant, %{is_open: new_status}) do
      {:ok, updated_restaurant} ->
        status_message = if new_status, do: "Restaurant opened!", else: "Restaurant closed"

        socket =
          socket
          |> assign(:restaurant, updated_restaurant)
          |> put_flash(:info, status_message)

        {:noreply, socket}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Unable to update restaurant status")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_notification_center", _params, socket) do
    socket = assign(socket, :show_notification_center, !socket.assigns.show_notification_center)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dismiss_notification", %{"id" => notification_id}, socket) do
    updated_notifications = Enum.reject(socket.assigns.notifications, &(&1.id == notification_id))
    unread_count = Enum.count(updated_notifications, &(!&1.read))

    socket =
      socket
      |> assign(:notifications, updated_notifications)
      |> assign(:unread_count, unread_count)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:order_status_updated, updated_order, _old_status}, socket) do
    # Only update if this is our restaurant
    if updated_order.restaurant_id == socket.assigns.restaurant.id do
      # Refresh order counts
      pending_count = Orders.count_pending_confirmations(socket.assigns.restaurant.id)
      active_count = Orders.count_active_orders(socket.assigns.restaurant.id)

      socket =
        socket
        |> assign(:pending_count, pending_count)
        |> assign(:active_count, active_count)
        |> assign(:last_updated, DateTime.utc_now())
        |> assign(:connection_status, :connected)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:connection_status, status}, socket) do
    socket = assign(socket, :connection_status, status)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:notification_event, event}, socket) do
    # Convert notification event to our notification format and add to list
    notification = convert_event_to_notification(event)
    current_notifications = [notification | socket.assigns.notifications] |> Enum.take(5)
    unread_count = socket.assigns.unread_count + 1

    socket =
      socket
      |> assign(:notifications, current_notifications)
      |> assign(:unread_count, unread_count)

    {:noreply, socket}
  end

  # Helper function to convert notification events to display format
  defp convert_event_to_notification(event) do
    %{
      id: "event_#{event.id}",
      title: format_notification_title(event.event_type),
      message: format_notification_message(event),
      timestamp: event.inserted_at,
      priority: String.to_atom(event.priority || "normal"),
      read: false
    }
  end

  defp format_notification_title("order_status_changed"), do: "Order Status Update"
  defp format_notification_title("order_cancelled"), do: "Order Cancelled"
  defp format_notification_title("delivery_delayed"), do: "Delivery Delayed"
  defp format_notification_title("promotion"), do: "Promotion Active"
  defp format_notification_title("newsletter"), do: "Platform Newsletter"
  defp format_notification_title("system_announcement"), do: "Platform Update"
  defp format_notification_title(_), do: "Restaurant Update"

  defp format_notification_message(event) do
    case event.event_type do
      "order_status_changed" ->
        order_id = event.data["order_id"] || "Unknown"
        new_status = event.data["new_status"] || "updated"
        "Order ##{order_id} is now #{new_status}"

      "order_cancelled" ->
        order_id = event.data["order_id"] || "Unknown"
        reason = event.data["reason"] || "No reason provided"
        "Order ##{order_id} cancelled: #{reason}"

      "delivery_delayed" ->
        order_id = event.data["order_id"] || "Unknown"
        delay_reason = event.data["delay_reason"] || "Unexpected delay"
        delay_minutes = event.data["estimated_delay_minutes"] || "unknown"
        "Order ##{order_id} delayed by #{delay_minutes} min: #{delay_reason}"

      "promotion" ->
        title = event.data["title"] || "New Promotion"
        message = event.data["message"] || "Promotion is now active"

        "#{title}: #{String.slice(message, 0, 80)}#{if String.length(message) > 80, do: "...", else: ""}"

      "newsletter" ->
        title = event.data["title"] || "Platform Newsletter"
        message = event.data["message"] || "New newsletter available"

        "#{title}: #{String.slice(message, 0, 80)}#{if String.length(message) > 80, do: "...", else: ""}"

      "system_announcement" ->
        title = event.data["title"] || "System Update"
        message = event.data["message"] || "System announcement"
        "#{title}: #{message}"

      _ ->
        event.data["message"] || "Restaurant notification"
    end
  end

  defp format_time_ago(timestamp) do
    seconds_ago = DateTime.diff(DateTime.utc_now(), timestamp, :second)

    cond do
      seconds_ago < 60 -> "#{seconds_ago}s ago"
      seconds_ago < 3600 -> "#{div(seconds_ago, 60)}m ago"
      seconds_ago < 86400 -> "#{div(seconds_ago, 3600)}h ago"
      true -> "#{div(seconds_ago, 86400)}d ago"
    end
  end
end
