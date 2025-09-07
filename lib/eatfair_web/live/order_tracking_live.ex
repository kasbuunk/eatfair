defmodule EatfairWeb.OrderTrackingLive do
  use EatfairWeb, :live_view

  alias Eatfair.Orders
  alias Phoenix.PubSub

  @impl true
  def mount(%{"id" => order_id, "token" => token}, _session, socket) do
    # Mount single order tracking with anonymous token
    case Orders.get_order_tracking_by_token(token) do
      {:ok, tracking_data} ->
        if to_string(tracking_data.order.id) == order_id do
          mount_order_tracking(socket, tracking_data, :token)
        else
          invalid_tracking_redirect(socket)
        end

      {:error, :invalid_token} ->
        invalid_tracking_redirect(socket)

      _error ->
        invalid_tracking_redirect(socket)
    end
  end

  @impl true
  def mount(%{"id" => order_id}, _session, socket) do
    # Mount single order tracking for authenticated users
    current_user = socket.assigns.current_scope.user

    case Orders.get_order_tracking_data(String.to_integer(order_id)) do
      {:ok, tracking_data} ->
        order = tracking_data.order

        # Verify customer owns this order
        if order.customer_id != current_user.id do
          socket =
            socket
            |> put_flash(:error, "Order not found")
            |> redirect(to: ~p"/orders/track")

          {:ok, socket}
        else
          mount_order_tracking(socket, tracking_data, :authenticated)
        end

      {:error, :order_not_found} ->
        socket =
          socket
          |> put_flash(:error, "Order not found")
          |> redirect(to: ~p"/orders/track")

        {:ok, socket}

      _error ->
        socket =
          socket
          |> put_flash(:error, "Unable to load order tracking")
          |> redirect(to: ~p"/orders/track")

        {:ok, socket}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    # Mount all orders tracking page
    current_user = socket.assigns.current_scope.user

    # Subscribe to order updates for this user
    PubSub.subscribe(Eatfair.PubSub, "order_tracking:#{current_user.id}")

    active_orders = Orders.list_active_customer_orders(current_user.id)

    socket =
      socket
      |> assign(:active_orders, active_orders)
      |> assign(:page_title, "Track Your Orders")
      |> assign(:show_all, true)

    {:ok, socket}
  end

  @impl true
  def handle_info({:order_status_updated, updated_order, _old_status}, socket) do
    cond do
      # Single order page
      socket.assigns[:order] && socket.assigns.order.id == updated_order.id ->
        socket =
          socket
          |> assign(:order, updated_order)
          |> assign(:estimated_delivery, Orders.calculate_estimated_delivery(updated_order))
          |> put_flash(:info, "Order status updated: #{format_status(updated_order.status)}")

        {:noreply, socket}

      # All orders page  
      socket.assigns[:show_all] ->
        active_orders = Orders.list_active_customer_orders(socket.assigns.current_scope.user.id)

        socket =
          socket
          |> assign(:active_orders, active_orders)
          |> put_flash(:info, "Order ##{updated_order.id} status updated")

        {:noreply, socket}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:notification_event, event}, socket) do
    # Handle real-time notification events
    if event.event_type == "order_status_changed" do
      message = format_notification_message(event)
      socket = put_flash(socket, :info, message)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(%{show_all: true} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto p-6">
        <.header>
          Track Your Orders
          <:subtitle>Real-time updates on all your active orders</:subtitle>
        </.header>

        <div class="mt-8">
          <%= if @active_orders == [] do %>
            <div class="text-center py-12">
              <.icon name="hero-shopping-bag" class="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">No Active Orders</h3>
              <p class="text-gray-500 mb-6">You don't have any orders in progress right now.</p>
              <.link
                navigate={~p"/restaurants"}
                class="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
              >
                Discover Restaurants
              </.link>
            </div>
          <% else %>
            <div class="space-y-6">
              <%= for order <- @active_orders do %>
                <div class="bg-white shadow-lg rounded-lg p-6 border border-gray-200">
                  <div class="flex justify-between items-start mb-4">
                    <div>
                      <h3 class="text-lg font-semibold text-gray-900">Order #{order.id}</h3>
                      <p class="text-sm text-gray-500">{order.restaurant.name}</p>
                    </div>
                    <div class="text-right">
                      {render_order_status(order)}
                    </div>
                  </div>

                  <div class="grid md:grid-cols-2 gap-6">
                    <div>
                      <h4 class="font-medium text-gray-900 mb-2">Items Ordered</h4>
                      <div class="space-y-2">
                        <%= for item <- order.order_items do %>
                          <div class="flex justify-between text-sm">
                            <span>{item.quantity}× {item.meal.name}</span>
                            <span class="font-medium">€{item.meal.price}</span>
                          </div>
                        <% end %>
                      </div>
                    </div>

                    <div>
                      <h4 class="font-medium text-gray-900 mb-2">Delivery Information</h4>
                      <p class="text-sm text-gray-600">{order.delivery_address}</p>
                      <%= if order.delivery_notes do %>
                        <p class="text-sm text-gray-500 mt-1">{order.delivery_notes}</p>
                      <% end %>
                      <%= if estimated = Orders.calculate_estimated_delivery(order) do %>
                        <p class="text-sm text-blue-600 mt-2">
                          <.icon name="hero-clock" class="h-4 w-4 inline" />
                          Estimated arrival: {format_estimated_time(estimated)}
                        </p>
                      <% end %>
                    </div>
                  </div>

                  <div class="mt-6 flex justify-between items-center">
                    <div class="text-lg font-semibold">
                      Total: €{order.total_price}
                    </div>
                    <.link
                      navigate={~p"/orders/track/#{order.id}"}
                      class="text-blue-600 hover:text-blue-800 text-sm font-medium"
                    >
                      View Details →
                    </.link>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto p-6">
        <.header>
          Order #{@order.id}
          <:subtitle>{@order.restaurant.name}</:subtitle>
        </.header>
        
    <!-- Order Status Timeline -->
        <div class="mt-8 bg-white shadow-lg rounded-lg p-6">
          {render_status_timeline(@order)}
        </div>
        
    <!-- Order Details -->
        <div class="mt-6 grid md:grid-cols-2 gap-6">
          <!-- Items Ordered -->
          <div class="bg-white shadow-lg rounded-lg p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Your Order</h3>
            <div class="space-y-3">
              <%= for item <- @order.order_items do %>
                <div class="flex justify-between items-center">
                  <div>
                    <span class="font-medium">{item.quantity}× {item.meal.name}</span>
                  </div>
                  <span class="font-medium">€{item.meal.price}</span>
                </div>
              <% end %>
            </div>
            <div class="border-t border-gray-200 pt-3 mt-4">
              <div class="flex justify-between items-center text-lg font-semibold">
                <span>Total</span>
                <span>€{@order.total_price}</span>
              </div>
            </div>
          </div>
          
    <!-- Delivery Information -->
          <div class="bg-white shadow-lg rounded-lg p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Delivery Information</h3>
            <div class="space-y-3">
              <div>
                <h4 class="font-medium text-gray-700">Address</h4>
                <p class="text-gray-600">{@order.delivery_address}</p>
              </div>
              <%= if @order.delivery_notes do %>
                <div>
                  <h4 class="font-medium text-gray-700">Special Instructions</h4>
                  <p class="text-gray-600">{@order.delivery_notes}</p>
                </div>
              <% end %>
              <%= if @estimated_delivery do %>
                <div>
                  <h4 class="font-medium text-gray-700">Estimated Arrival</h4>
                  <p class="text-blue-600 font-medium">
                    <.icon name="hero-clock" class="h-4 w-4 inline" />
                    {format_estimated_time(@estimated_delivery)}
                  </p>
                </div>
              <% end %>
              <%= if @order.is_delayed and @order.delay_reason do %>
                <div class="bg-amber-50 border border-amber-200 rounded-lg p-3">
                  <h4 class="font-medium text-amber-800">Slight Delay</h4>
                  <p class="text-amber-700 text-sm mt-1">{@order.delay_reason}</p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Back to All Orders -->
        <div class="mt-6 text-center">
          <.link navigate={~p"/orders/track"} class="text-blue-600 hover:text-blue-800 font-medium">
            ← View All Orders
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Helper functions for rendering

  defp render_order_status(order) do
    {icon, color, text} =
      case order.status do
        "confirmed" -> {"hero-check-circle", "text-green-600", "Order Confirmed"}
        "preparing" -> {"hero-fire", "text-orange-600", "Preparing Your Order"}
        "ready" -> {"hero-clock", "text-blue-600", "Ready for Pickup"}
        "out_for_delivery" -> {"hero-truck", "text-purple-600", "Out for Delivery"}
        "delivered" -> {"hero-check-badge", "text-green-700", "Delivered"}
        "cancelled" -> {"hero-x-circle", "text-red-600", "Order Cancelled"}
        _ -> {"hero-question-mark-circle", "text-gray-500", "Processing"}
      end

    assigns = %{icon: icon, color: color, text: text}

    ~H"""
    <div class={["flex items-center", @color]}>
      <.icon name={@icon} class="h-5 w-5 mr-2" />
      <span class="font-medium">{@text}</span>
    </div>
    """
  end

  defp render_status_timeline(order) do
    statuses = [
      {"confirmed", "Order Confirmed", "We've received your order and payment"},
      {"preparing", "Preparing Your Order", "The kitchen is working on your delicious meal"},
      {"ready", "Ready for Pickup", "Your order is ready and waiting for delivery"},
      {"out_for_delivery", "Out for Delivery", "Your order is on its way to you"},
      {"delivered", "Delivered", "Enjoy your meal!"}
    ]

    current_status = order.status

    current_index =
      Enum.find_index(statuses, fn {status, _, _} -> status == current_status end) || 0

    assigns = %{
      statuses: statuses,
      current_index: current_index,
      current_status: current_status,
      order: order
    }

    ~H"""
    <div class="space-y-4">
      <%= for {{status, title, description}, index} <- Enum.with_index(@statuses) do %>
        <% is_completed = index <= @current_index
        is_current = status == @current_status
        is_future = index > @current_index %>
        <div class={[
          "flex items-start",
          is_current && "border-l-4 border-blue-500 pl-4 bg-blue-50 rounded-r-lg py-2",
          is_completed && !is_current && "text-green-600",
          is_future && "text-gray-400"
        ]}>
          <div class="flex-shrink-0 mt-1">
            <%= if is_completed do %>
              <.icon
                name="hero-check-circle"
                class={if is_current, do: "h-6 w-6 text-blue-600", else: "h-6 w-6 text-green-600"}
              />
            <% else %>
              <div class="h-6 w-6 border-2 border-gray-300 rounded-full"></div>
            <% end %>
          </div>
          <div class="ml-4">
            <h3 class={[
              "font-semibold",
              is_current && "text-blue-900",
              is_completed && !is_current && "text-green-700"
            ]}>
              {title}
            </h3>
            <p class={[
              "text-sm",
              is_current && "text-blue-700",
              is_completed && !is_current && "text-green-600",
              is_future && "text-gray-500"
            ]}>
              {description}
            </p>
            <% timestamp = get_status_timestamp(@order, status) %>
            <%= if status == @current_status && timestamp do %>
              <p class="text-xs text-blue-600 mt-1">{format_timestamp(timestamp)}</p>
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @current_status == "cancelled" do %>
        <div class="flex items-start border-l-4 border-red-500 pl-4 bg-red-50 rounded-r-lg py-2">
          <div class="flex-shrink-0 mt-1">
            <.icon name="hero-x-circle" class="h-6 w-6 text-red-600" />
          </div>
          <div class="ml-4">
            <h3 class="font-semibold text-red-900">Order Cancelled</h3>
            <p class="text-sm text-red-700">This order has been cancelled</p>
            <%= if @order.delay_reason do %>
              <p class="text-sm text-red-600 mt-1">{@order.delay_reason}</p>
            <% end %>
            <%= if @order.cancelled_at do %>
              <p class="text-xs text-red-600 mt-1">{format_timestamp(@order.cancelled_at)}</p>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_status_timestamp(order, status) do
    case status do
      "confirmed" -> order.confirmed_at
      "preparing" -> order.preparing_at
      "ready" -> order.ready_at
      "out_for_delivery" -> order.out_for_delivery_at
      "delivered" -> order.delivered_at
      "cancelled" -> order.cancelled_at
      _ -> nil
    end
  end

  defp format_status(status) do
    case status do
      "confirmed" -> "Order Confirmed"
      "preparing" -> "Preparing Your Order"
      "ready" -> "Ready for Pickup"
      "out_for_delivery" -> "Out for Delivery"
      "delivered" -> "Delivered"
      "cancelled" -> "Order Cancelled"
      _ -> "Processing"
    end
  end

  defp format_estimated_time(datetime) do
    now = NaiveDateTime.utc_now()
    diff_minutes = NaiveDateTime.diff(datetime, now, :minute)

    cond do
      diff_minutes <= 0 -> "Any moment now"
      diff_minutes < 60 -> "#{diff_minutes} minutes"
      diff_minutes < 120 -> "About 1 hour"
      true -> "About #{div(diff_minutes, 60)} hours"
    end
  end

  defp format_timestamp(timestamp) do
    Calendar.strftime(timestamp, "%I:%M %p on %B %d")
  end

  defp format_notification_message(event) do
    data = event.data

    case data["new_status"] do
      "confirmed" ->
        "Your order from #{data["restaurant_name"]} has been confirmed!"

      "preparing" ->
        "Great news! #{data["restaurant_name"]} is now preparing your order."

      "ready" ->
        "Your order from #{data["restaurant_name"]} is ready for delivery!"

      "out_for_delivery" ->
        "Your order is on its way! Estimated arrival soon."

      "delivered" ->
        "Delivered! Enjoy your meal from #{data["restaurant_name"]}."

      "cancelled" ->
        "Unfortunately, your order from #{data["restaurant_name"]} has been cancelled."

      _ ->
        "Your order status has been updated."
    end
  end

  # Helper functions for mounting order tracking

  defp mount_order_tracking(socket, tracking_data, access_type) do
    order = tracking_data.order
    current_status = tracking_data.current_status
    status_history = tracking_data.status_history

    # Subscribe to real-time updates based on access type
    case access_type do
      :authenticated ->
        PubSub.subscribe(Eatfair.PubSub, "order_tracking:#{order.id}")

      :token ->
        if order.tracking_token do
          PubSub.subscribe(Eatfair.PubSub, "order_tracking_token:#{order.tracking_token}")
        end
    end

    socket =
      socket
      |> assign(:order, order)
      |> assign(:current_status, current_status)
      |> assign(:status_history, status_history)
      |> assign(:courier_location, tracking_data[:courier_location])
      |> assign(:estimated_delivery, Orders.calculate_estimated_delivery(order))
      |> assign(:access_type, access_type)
      |> assign(:page_title, "Track Order ##{order.id}")

    {:ok, socket}
  end

  defp invalid_tracking_redirect(socket) do
    socket =
      socket
      |> put_flash(:error, "Invalid tracking link. Please check your email for the correct link.")
      |> redirect(to: ~p"/")

    {:ok, socket}
  end
end
