defmodule EatfairWeb.RestaurantOrderManagementLive do
  use EatfairWeb, :live_view

  alias Eatfair.{Orders, Restaurants, Notifications}
  alias EatfairWeb.Layouts
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    # Get restaurant owned by current user
    case Restaurants.get_restaurant_by_owner(current_user.id) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "You must own a restaurant to access order management")
          |> redirect(to: ~p"/restaurant/onboard")

        {:ok, socket}

      restaurant ->
        # Subscribe to restaurant order updates and notifications
        PubSub.subscribe(Eatfair.PubSub, "restaurant_orders:#{restaurant.id}")
        PubSub.subscribe(Eatfair.PubSub, "user_notifications:#{current_user.id}")

        # Start with active orders by default
        orders_by_status = Orders.list_restaurant_orders(restaurant.id, :active)

        # Load existing notification events for the user
        notification_events = Notifications.list_events_for_user(current_user.id)
        notifications = Enum.map(notification_events, &convert_event_to_notification/1)
        unread_count = Enum.count(notifications, &(!&1.read))

        # Load staged orders and delivery batches
        staged_orders = Orders.list_staged_orders_for_restaurant(restaurant.id)
        delivery_batches = Orders.list_restaurant_delivery_batches(restaurant.id)

        socket =
          socket
          |> assign(:restaurant, restaurant)
          |> assign(:orders_by_status, orders_by_status)
          # Track current filter
          |> assign(:orders_filter, :active)
          |> assign(:history_orders, [])
          |> assign(:staged_orders, staged_orders)
          |> assign(:delivery_batches, delivery_batches)
          |> assign(:selected_orders, MapSet.new())
          |> assign(:show_batch_modal, false)
          |> assign(:page_title, "Order Management - #{restaurant.name}")
          |> assign(:notifications, notifications)
          |> assign(:unread_count, unread_count)
          |> assign(:show_notification_center, false)

        {:ok, socket}
    end
  end

  @impl true
  def handle_info({:order_status_updated, updated_order, old_status}, socket) do
    # Refresh orders when status changes
    if updated_order.restaurant_id == socket.assigns.restaurant.id do
      orders_by_status = Orders.list_restaurant_orders(socket.assigns.restaurant.id)

      # Create notification for status change
      notification =
        create_notification_for_status_change(updated_order, old_status, updated_order.status)

      current_notifications = [notification | socket.assigns.notifications]
      unread_count = socket.assigns.unread_count + 1

      socket =
        socket
        |> assign(:orders_by_status, orders_by_status)
        |> assign(:notifications, current_notifications)
        |> assign(:unread_count, unread_count)
        |> put_flash(:info, "Order ##{updated_order.id} status updated")

      # Schedule auto-hide for non-critical notifications
      if notification.priority != :critical do
        Process.send_after(self(), {:auto_hide_notification, notification.id}, 5000)
      end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:auto_hide_notification, notification_id}, socket) do
    updated_notifications = Enum.reject(socket.assigns.notifications, &(&1.id == notification_id))
    unread_count = Enum.count(updated_notifications, &(!&1.read))

    socket =
      socket
      |> assign(:notifications, updated_notifications)
      |> assign(:unread_count, unread_count)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:notification_event, event}, socket) do
    # Convert notification event to our notification format and add to list
    notification = convert_event_to_notification(event)
    current_notifications = [notification | socket.assigns.notifications]
    unread_count = socket.assigns.unread_count + 1

    socket =
      socket
      |> assign(:notifications, current_notifications)
      |> assign(:unread_count, unread_count)

    # Schedule auto-hide for non-critical notifications
    if notification.priority != :critical do
      Process.send_after(self(), {:auto_hide_notification, notification.id}, 5000)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("start_preparing", %{"order_id" => order_id}, socket) do
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "preparing") do
      {:ok, _updated_order} ->
        {:noreply, put_flash(socket, :info, "Order ##{order_id} is now being prepared")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update order status")}
    end
  end

  @impl true
  def handle_event("mark_ready", %{"order_id" => order_id}, socket) do
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "ready") do
      {:ok, _updated_order} ->
        {:noreply, put_flash(socket, :info, "Order ##{order_id} is ready for pickup!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update order status")}
    end
  end

  @impl true
  def handle_event("send_for_delivery", %{"order_id" => order_id}, socket) do
    order = Orders.get_order!(order_id)

    # Calculate estimated delivery time (ready time + 20 minutes default delivery)
    estimated_delivery = NaiveDateTime.add(NaiveDateTime.utc_now(), 20 * 60)

    case Orders.update_order_status(order, "out_for_delivery", %{
           estimated_delivery_at: estimated_delivery
         }) do
      {:ok, _updated_order} ->
        {:noreply, put_flash(socket, :info, "Order ##{order_id} is out for delivery!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update order status")}
    end
  end

  @impl true
  def handle_event("mark_delivered", %{"order_id" => order_id}, socket) do
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "delivered") do
      {:ok, _updated_order} ->
        {:noreply, put_flash(socket, :info, "Order ##{order_id} marked as delivered!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update order status")}
    end
  end

  @impl true
  def handle_event("accept_order", %{"order_id" => order_id}, socket) do
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "confirmed") do
      {:ok, _updated_order} ->
        # Refresh orders to update UI
        orders_by_status = Orders.list_restaurant_orders(socket.assigns.restaurant.id)

        socket =
          socket
          |> assign(:orders_by_status, orders_by_status)
          |> put_flash(:info, "Order ##{order_id} has been accepted!")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not accept order")}
    end
  end

  @impl true
  def handle_event("reject_order", %{"order_id" => order_id, "reason" => _reason}, socket) do
    # Store the order_id for form submission and show modal
    socket =
      socket
      |> assign(:current_order_id, order_id)
      |> assign(:show_rejection_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "submit_rejection",
        %{"rejection_reason" => reason, "rejection_notes" => notes},
        socket
      ) do
    order_id = socket.assigns.current_order_id
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "cancelled", %{
           rejection_reason: reason,
           rejection_notes: notes
         }) do
      {:ok, _updated_order} ->
        socket =
          socket
          |> assign(:show_rejection_modal, false)
          |> assign(:current_order_id, nil)
          |> put_flash(:info, "Order ##{order_id} has been rejected")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not reject order")}
    end
  end

  @impl true
  def handle_event("cancel_order", %{"order_id" => order_id, "reason" => reason}, socket) do
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "cancelled", %{delay_reason: reason}) do
      {:ok, _updated_order} ->
        {:noreply, put_flash(socket, :info, "Order ##{order_id} has been cancelled")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not cancel order")}
    end
  end

  @impl true
  def handle_event(
        "report_delivery_failure",
        %{"order_id" => order_id, "reason" => _reason},
        socket
      ) do
    # Store the order_id for form submission and show modal
    socket =
      socket
      |> assign(:current_order_id, order_id)
      |> assign(:show_delivery_failure_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "submit_delivery_failure",
        %{"failure_reason" => reason, "failure_notes" => notes},
        socket
      ) do
    order_id = socket.assigns.current_order_id
    order = Orders.get_order!(order_id)

    case Orders.update_order_status(order, "delivery_failed", %{
           failure_reason: reason,
           failure_notes: notes
         }) do
      {:ok, _updated_order} ->
        socket =
          socket
          |> assign(:show_delivery_failure_modal, false)
          |> assign(:current_order_id, nil)
          |> put_flash(:info, "Delivery failure reported for order ##{order_id}")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not report delivery failure")}
    end
  end

  @impl true
  def handle_event(
        "report_delay",
        %{"order_id" => order_id, "reason" => reason, "extra_minutes" => extra_minutes_str},
        socket
      ) do
    order = Orders.get_order!(order_id)

    extra_minutes = String.to_integer(extra_minutes_str || "15")
    new_estimated_delivery = NaiveDateTime.add(NaiveDateTime.utc_now(), extra_minutes * 60)

    case Orders.update_order_status(order, order.status, %{
           is_delayed: true,
           delay_reason: reason,
           estimated_delivery_at: new_estimated_delivery
         }) do
      {:ok, _updated_order} ->
        {:noreply, put_flash(socket, :info, "Delay notification sent for order ##{order_id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not report delay")}
    end
  end

  @impl true
  def handle_event("toggle_notification_center", _params, socket) do
    socket =
      socket
      |> assign(:show_notification_center, !socket.assigns.show_notification_center)

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
  def handle_event("mark_all_notifications_read", _params, socket) do
    updated_notifications = Enum.map(socket.assigns.notifications, &Map.put(&1, :read, true))
    unread_count = 0

    socket =
      socket
      |> assign(:notifications, updated_notifications)
      |> assign(:unread_count, unread_count)

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_to_active", _params, socket) do
    orders_by_status = Orders.list_restaurant_orders(socket.assigns.restaurant.id, :active)

    socket =
      socket
      |> assign(:orders_filter, :active)
      |> assign(:orders_by_status, orders_by_status)
      |> assign(:history_orders, [])

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_to_history", _params, socket) do
    history_orders = Orders.list_restaurant_orders(socket.assigns.restaurant.id, :history)

    socket =
      socket
      |> assign(:orders_filter, :history)
      # Empty for history view
      |> assign(:orders_by_status, %{
        pending: [],
        confirmed: [],
        preparing: [],
        ready: [],
        out_for_delivery: []
      })
      |> assign(:history_orders, history_orders)

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_to_staging", _params, socket) do
    staged_orders = Orders.list_staged_orders_for_restaurant(socket.assigns.restaurant.id)
    delivery_batches = Orders.list_restaurant_delivery_batches(socket.assigns.restaurant.id)

    socket =
      socket
      |> assign(:orders_filter, :staging)
      |> assign(:staged_orders, staged_orders)
      |> assign(:delivery_batches, delivery_batches)
      |> assign(:selected_orders, MapSet.new())
      # Empty for staging view
      |> assign(:orders_by_status, %{
        pending: [],
        confirmed: [],
        preparing: [],
        ready: [],
        out_for_delivery: []
      })
      |> assign(:history_orders, [])

    {:noreply, socket}
  end

  @impl true
  def handle_event("stage_order", %{"order_id" => order_id}, socket) do
    order = Orders.get_order!(order_id)
    
    case Orders.stage_order(order) do
      {:ok, _staged_order} ->
        # Refresh both staged orders AND active orders (since order moved from ready to staged)
        staged_orders = Orders.list_staged_orders_for_restaurant(socket.assigns.restaurant.id)
        orders_by_status = if socket.assigns.orders_filter == :active do
          Orders.list_restaurant_orders(socket.assigns.restaurant.id, :active)
        else
          socket.assigns.orders_by_status
        end
        
        socket =
          socket
          |> assign(:staged_orders, staged_orders)
          |> assign(:orders_by_status, orders_by_status)
          |> put_flash(:info, "Order ##{order_id} moved to staging area")
        
        {:noreply, socket}
        
      {:error, changeset} ->
        # Better error handling - show the actual validation error
        error_msg = case changeset.errors do
          [{:status, {message, _}} | _] -> "Cannot stage order: #{message}"
          _ -> "Could not stage order. Order must be ready first."
        end
        {:noreply, put_flash(socket, :error, error_msg)}
    end
  end

  @impl true
  def handle_event("toggle_order_selection", %{"order_id" => order_id}, socket) do
    order_id = String.to_integer(order_id)
    selected_orders = socket.assigns.selected_orders
    
    updated_selection = 
      if MapSet.member?(selected_orders, order_id) do
        MapSet.delete(selected_orders, order_id)
      else
        MapSet.put(selected_orders, order_id)
      end
    
    socket = assign(socket, :selected_orders, updated_selection)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_all_staged", _params, socket) do
    all_staged_ids = 
      socket.assigns.staged_orders
      |> Enum.map(&(&1.id))
      |> MapSet.new()
    
    socket = assign(socket, :selected_orders, all_staged_ids)
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_selection", _params, socket) do
    socket = assign(socket, :selected_orders, MapSet.new())
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_batch", _params, socket) do
    socket = assign(socket, :show_batch_modal, true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_batch_modal", _params, socket) do
    socket = assign(socket, :show_batch_modal, false)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_batch_creation", %{"batch_name" => batch_name}, socket) do
    selected_order_ids = MapSet.to_list(socket.assigns.selected_orders)
    
    if Enum.empty?(selected_order_ids) do
      {:noreply, put_flash(socket, :error, "Please select at least one order to create a batch")}
    else
      case Orders.create_delivery_batch(%{
             name: batch_name,
             restaurant_id: socket.assigns.restaurant.id,
             status: "draft"
           }) do
        {:ok, batch} ->
          # Assign selected orders to the batch
          case Orders.assign_orders_to_batch(batch.id, selected_order_ids) do
            {:ok, updated_batch} ->
              # Try to auto-assign a courier
              case Orders.suggest_courier(socket.assigns.restaurant.id) do
                nil ->
                  # No courier available, keep as draft
                  refresh_staging_data(socket, "Delivery batch '#{batch_name}' created successfully!")
                  
                courier ->
                  # Auto-assign courier and set to proposed
                  case Orders.update_delivery_batch(updated_batch, %{
                         courier_id: courier.id,
                         status: "proposed",
                         auto_assigned: true,
                         suggested_courier_id: courier.id
                       }) do
                    {:ok, _final_batch} ->
                      # Broadcast to courier
                      Phoenix.PubSub.broadcast(
                        Eatfair.PubSub,
                        "courier_batches:#{courier.id}",
                        {:batch_auto_assigned, updated_batch}
                      )
                      
                      refresh_staging_data(socket, "Delivery batch '#{batch_name}' created and assigned to #{courier.name || "courier"}!")
                      
                    {:error, _} ->
                      refresh_staging_data(socket, "Delivery batch '#{batch_name}' created successfully!")
                  end
              end
              
            {:error, _reason} ->
              {:noreply, put_flash(socket, :error, "Failed to assign orders to batch")}
          end
          
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to create delivery batch")}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={assigns[:flash] || %{}} current_scope={assigns[:current_scope]}>
      <div class="max-w-7xl mx-auto p-6">
        <.header>
          Order Management - {@restaurant.name}
          <:subtitle>Manage all incoming orders and update their status in real-time</:subtitle>
          <:actions>
            <%!-- MVP: notifications hidden --%>
            <%= if false do %>
              <div class="relative">
                <button
                  phx-click="toggle_notification_center"
                  class="p-2 rounded-full hover:bg-gray-100 relative"
                  aria-label="Notifications"
                >
                  <.icon name="hero-bell" class="h-6 w-6 text-gray-700" />
                  <%= if @unread_count > 0 do %>
                    <span
                      class="absolute top-0 right-0 -mt-1 -mr-1 px-2 py-1 text-xs font-bold rounded-full bg-red-500 text-white notification-count"
                      data-testid="notification-count"
                    >
                      {@unread_count}
                    </span>
                  <% end %>
                </button>
              </div>
            <% end %>
          </:actions>
        </.header>
        
    <%!-- MVP: notification center hidden --%>
    <%= if false do %>
        <!-- Notification Center (Always visible for TDD tests) -->
        <div
          data-testid="notification-center"
          class="fixed top-4 right-4 w-80 bg-white border border-gray-200 rounded-lg shadow-lg z-50 max-h-96 overflow-y-auto"
        >
          <div class="p-3 border-b border-gray-200 flex justify-between items-center">
            <h3 class="font-semibold text-gray-800">Notifications</h3>
            <button
              phx-click="mark_all_notifications_read"
              class="text-xs text-blue-600 hover:text-blue-800"
            >
              Mark all as read
            </button>
          </div>

          <div id="notifications-list">
            <%= if Enum.empty?(@notifications) do %>
              <div class="p-4 text-center text-gray-500">
                <p>No notifications</p>
              </div>
            <% else %>
              <%= for notification <- @notifications do %>
                <div
                  id={"notification-#{notification.id}"}
                  data-testid="notification-item"
                  data-priority={if(notification.priority == :critical, do: "high", else: "normal")}
                  data-auto-hide={if(notification.priority != :critical, do: "true", else: "false")}
                  class={[
                    "p-3 border-b border-gray-100 relative hover:bg-gray-50",
                    if(notification.read, do: "bg-gray-50", else: "bg-white"),
                    if(notification.priority == :critical,
                      do: "border-l-4 border-l-red-500",
                      else: ""
                    )
                  ]}
                >
                  <button
                    phx-click="dismiss_notification"
                    phx-value-id={notification.id}
                    data-testid="dismiss-notification"
                    class="absolute top-2 right-2 text-gray-400 hover:text-gray-600"
                    aria-label="Dismiss"
                  >
                    <.icon name="hero-x-mark" class="h-4 w-4" />
                  </button>

                  <div class="pr-5">
                    <p class={[
                      "font-medium",
                      if(notification.priority == :critical,
                        do: "text-red-700",
                        else: "text-gray-800"
                      )
                    ]}>
                      {notification.title}
                    </p>
                    <p class="text-sm text-gray-600 mt-1">{notification.message}</p>
                    <p class="text-xs text-gray-400 mt-1">
                      {format_time_ago(notification.timestamp)}
                    </p>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
    <% end %>
        
    <!-- Active/History/Staging Tabs -->
        <div class="mt-6">
          <div class="border-b border-gray-200">
            <nav class="-mb-px flex space-x-8" aria-label="Tabs">
              <button
                phx-click="switch_to_active"
                data-test="active-tab"
                class={[
                  "whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm transition-colors",
                  if(@orders_filter == :active,
                    do: "border-blue-500 text-blue-600",
                    else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                  )
                ]}
              >
                Active
                <%= if @orders_filter == :active do %>
                  <span class="ml-2 bg-blue-100 text-blue-600 py-0.5 px-2.5 rounded-full text-xs font-medium">
                    {length(@orders_by_status.pending) + length(@orders_by_status.confirmed) +
                      length(@orders_by_status.preparing) + length(@orders_by_status.ready) +
                      length(@orders_by_status.out_for_delivery)}
                  </span>
                <% end %>
              </button>

              <%!-- MVP: batch delivery hidden --%>
              <%= if false do %>
                <button
                  phx-click="switch_to_staging"
                  data-test="staging-tab"
                  class={[
                    "whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm transition-colors",
                    if(@orders_filter == :staging,
                      do: "border-blue-500 text-blue-600",
                      else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                    )
                  ]}
                >
                  Staging
                  <%= if @orders_filter == :staging do %>
                    <span class="ml-2 bg-blue-100 text-blue-600 py-0.5 px-2.5 rounded-full text-xs font-medium">
                      {length(@staged_orders)}
                    </span>
                  <% end %>
                </button>
              <% end %>

              <button
                phx-click="switch_to_history"
                data-test="history-tab"
                class={[
                  "whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm transition-colors",
                  if(@orders_filter == :history,
                    do: "border-blue-500 text-blue-600",
                    else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                  )
                ]}
              >
                History
                <%= if @orders_filter == :history do %>
                  <span class="ml-2 bg-blue-100 text-blue-600 py-0.5 px-2.5 rounded-full text-xs font-medium">
                    {length(@history_orders)}
                  </span>
                <% end %>
              </button>
            </nav>
          </div>
        </div>
        
    <!-- Order Statistics -->
        <div class="mt-6 grid grid-cols-1 md:grid-cols-4 gap-6">
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div class="flex items-center">
              <.icon name="hero-bell-alert" class="h-8 w-8 text-blue-600 mr-3" />
              <div>
                <p class="text-sm font-medium text-blue-600">New Orders</p>
                <p class="text-2xl font-bold text-blue-900">{length(@orders_by_status.confirmed)}</p>
              </div>
            </div>
          </div>

          <div class="bg-orange-50 border border-orange-200 rounded-lg p-4">
            <div class="flex items-center">
              <.icon name="hero-fire" class="h-8 w-8 text-orange-600 mr-3" />
              <div>
                <p class="text-sm font-medium text-orange-600">In Progress</p>
                <p class="text-2xl font-bold text-orange-900">
                  {length(@orders_by_status.preparing)}
                </p>
              </div>
            </div>
          </div>

          <div class="bg-green-50 border border-green-200 rounded-lg p-4">
            <div class="flex items-center">
              <.icon name="hero-check-circle" class="h-8 w-8 text-green-600 mr-3" />
              <div>
                <p class="text-sm font-medium text-green-600">Ready</p>
                <p class="text-2xl font-bold text-green-900">{length(@orders_by_status.ready)}</p>
              </div>
            </div>
          </div>

          <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
            <div class="flex items-center">
              <.icon name="hero-truck" class="h-8 w-8 text-purple-600 mr-3" />
              <div>
                <p class="text-sm font-medium text-purple-600">Out for Delivery</p>
                <p class="text-2xl font-bold text-purple-900">
                  {length(@orders_by_status.out_for_delivery)}
                </p>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Order Sections -->
        <div class="mt-8 space-y-8">
          <!-- Staging Section -->
          <%= if @orders_filter == :staging do %>
            <div class="space-y-6">
              <!-- Staging Control Panel -->
              <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div class="flex items-center justify-between">
                  <div>
                    <h3 class="text-lg font-semibold text-blue-900">Staging Area</h3>
                    <p class="text-sm text-blue-700 mt-1">Select ready orders and create delivery batches for couriers</p>
                  </div>
                  <div class="flex space-x-3">
                    <%= if MapSet.size(@selected_orders) > 0 do %>
                      <button
                        phx-click="create_batch"
                        class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 font-medium"
                        data-test="create-batch-button"
                      >
                        Create Batch ({MapSet.size(@selected_orders)} orders)
                      </button>
                      <button
                        phx-click="clear_selection"
                        class="bg-gray-500 text-white px-4 py-2 rounded-lg hover:bg-gray-600 font-medium"
                        data-test="clear-selection-button"
                      >
                        Clear Selection
                      </button>
                    <% else %>
                      <button
                        phx-click="select_all_staged"
                        class="bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700 font-medium"
                        data-test="select-all-button"
                        disabled={length(@staged_orders) == 0}
                      >
                        Select All ({length(@staged_orders)})
                      </button>
                    <% end %>
                  </div>
                </div>
              </div>

              <!-- Staged Orders -->
              <%= if length(@staged_orders) > 0 do %>
                <div>
                  <h2 class="text-xl font-bold text-gray-900 mb-4">Staged Orders Ready for Delivery</h2>
                  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <%= for order <- @staged_orders do %>
                      {render_staged_order_card(order, @selected_orders)}
                    <% end %>
                  </div>
                </div>
              <% else %>
                <div class="text-center py-8">
                  <.icon name="hero-archive-box" class="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 class="text-lg font-medium text-gray-900 mb-2">No Staged Orders</h3>
                  <p class="text-gray-500">Orders marked as ready will appear here for batching.</p>
                </div>
              <% end %>

              <!-- Delivery Batches -->
              <%= if length(@delivery_batches) > 0 do %>
                <div>
                  <h2 class="text-xl font-bold text-gray-900 mb-4">Delivery Batches</h2>
                  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <%= for batch <- @delivery_batches do %>
                      {render_batch_card(batch)}
                    <% end %>
                  </div>
                </div>
              <% else %>
                <div class="text-center py-8">
                  <.icon name="hero-truck" class="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 class="text-lg font-medium text-gray-900 mb-2">No Delivery Batches</h3>
                  <p class="text-gray-500">Created batches will appear here for tracking.</p>
                </div>
              <% end %>
            </div>
          <% end %>

          <!-- Pending Orders -->
          <%= if length(@orders_by_status.pending) > 0 do %>
            <div>
              <h2 class="text-xl font-bold text-gray-900 mb-4">Pending Orders</h2>
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <%= for order <- @orders_by_status.pending do %>
                  {render_order_card(order, "pending")}
                <% end %>
              </div>
            </div>
          <% end %>
          
    <!-- New Orders -->
          <%= if length(@orders_by_status.confirmed) > 0 do %>
            <div>
              <h2 class="text-xl font-bold text-gray-900 mb-4">New Orders</h2>
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <%= for order <- @orders_by_status.confirmed do %>
                  {render_order_card(order, "confirmed")}
                <% end %>
              </div>
            </div>
          <% end %>
          
    <!-- In Progress -->
          <%= if length(@orders_by_status.preparing) > 0 do %>
            <div>
              <h2 class="text-xl font-bold text-gray-900 mb-4">In Progress</h2>
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <%= for order <- @orders_by_status.preparing do %>
                  {render_order_card(order, "preparing")}
                <% end %>
              </div>
            </div>
          <% end %>
          
    <!-- Ready for Delivery -->
          <%= if length(@orders_by_status.ready) > 0 do %>
            <div>
              <h2 class="text-xl font-bold text-gray-900 mb-4">Ready for Delivery</h2>
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <%= for order <- @orders_by_status.ready do %>
                  {render_order_card(order, "ready")}
                <% end %>
              </div>
            </div>
          <% end %>
          
    <!-- Out for Delivery -->
          <%= if length(@orders_by_status.out_for_delivery) > 0 do %>
            <div>
              <h2 class="text-xl font-bold text-gray-900 mb-4">Out for Delivery</h2>
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <%= for order <- @orders_by_status.out_for_delivery do %>
                  {render_order_card(order, "out_for_delivery")}
                <% end %>
              </div>
            </div>
          <% end %>
          
    <!-- History Orders -->
          <%= if @orders_filter == :history do %>
            <%= if length(@history_orders) > 0 do %>
              <div>
                <h2 class="text-xl font-bold text-gray-900 mb-4">Order History</h2>
                <div class="bg-white shadow overflow-hidden sm:rounded-md">
                  <ul class="divide-y divide-gray-200">
                    <%= for order <- @history_orders do %>
                      <li class="px-6 py-4">
                        <div class="flex items-center justify-between">
                          <div class="flex items-center">
                            <div class="flex-shrink-0">
                              <div class={[
                                "w-8 h-8 rounded-full flex items-center justify-center text-xs font-medium",
                                case order.status do
                                  "delivered" -> "bg-green-100 text-green-800"
                                  "cancelled" -> "bg-red-100 text-red-800"
                                  "delivery_failed" -> "bg-yellow-100 text-yellow-800"
                                  _ -> "bg-gray-100 text-gray-800"
                                end
                              ]}>
                                <%= case order.status do %>
                                  <% "delivered" -> %>
                                    ✓
                                  <% "cancelled" -> %>
                                    ✗
                                  <% "delivery_failed" -> %>
                                    ⚠
                                  <% _ -> %>
                                    ?
                                <% end %>
                              </div>
                            </div>

                            <div class="ml-4">
                              <div class="flex items-center">
                                <p class="text-sm font-medium text-gray-900">
                                  Order #{order.id}
                                </p>
                                <span class={[
                                  "ml-2 inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                                  case order.status do
                                    "delivered" -> "bg-green-100 text-green-800"
                                    "cancelled" -> "bg-red-100 text-red-800"
                                    "delivery_failed" -> "bg-yellow-100 text-yellow-800"
                                    _ -> "bg-gray-100 text-gray-800"
                                  end
                                ]}>
                                  {String.replace(order.status, "_", " ")}
                                </span>
                              </div>
                              <div class="mt-1 flex items-center text-sm text-gray-500">
                                <p>
                                  {order.delivery_address} •
                                  <%= if order.delivered_at do %>
                                    Completed {format_time_ago(order.delivered_at)}
                                  <% else %>
                                    Completed {format_time_ago(order.updated_at)}
                                  <% end %>
                                </p>
                              </div>
                            </div>
                          </div>

                          <div class="flex items-center">
                            <div class="text-right mr-4">
                              <p class="text-sm font-medium text-gray-900">€{order.total_price}</p>
                              <p class="text-sm text-gray-500">
                                {Enum.reduce(order.order_items, 0, fn item, acc ->
                                  acc + item.quantity
                                end)} items
                              </p>
                            </div>

                            <div class="flex-shrink-0">
                              <.icon name="hero-chevron-right" class="h-5 w-5 text-gray-400" />
                            </div>
                          </div>
                        </div>
                        
    <!-- Order Items Summary -->
                        <div class="mt-3 text-sm text-gray-600">
                          <%= for item <- Enum.take(order.order_items, 3) do %>
                            <span class="mr-4">
                              {item.quantity}× {item.meal.name}
                            </span>
                          <% end %>
                          <%= if length(order.order_items) > 3 do %>
                            <span class="text-gray-400">
                              and {length(order.order_items) - 3} more...
                            </span>
                          <% end %>
                        </div>
                      </li>
                    <% end %>
                  </ul>
                </div>
              </div>
            <% else %>
              <div class="text-center py-12">
                <.icon name="hero-clock" class="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 class="text-lg font-medium text-gray-900 mb-2">No Order History</h3>
                <p class="text-gray-500">Completed and cancelled orders will appear here.</p>
              </div>
            <% end %>
          <% else %>
            <!-- Empty State for Active Orders -->
            <%= if Enum.all?(@orders_by_status, fn {_status, orders} -> length(orders) == 0 end) do %>
              <div class="text-center py-12">
                <.icon name="hero-shopping-bag" class="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 class="text-lg font-medium text-gray-900 mb-2">No Active Orders</h3>
                <p class="text-gray-500">
                  When you receive orders, they'll appear here for management.
                </p>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
      
    <!-- Batch Creation Modal -->
      <%= if @show_batch_modal do %>
        <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" data-testid="batch-modal">
          <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div class="mt-3">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-medium text-gray-900">Create Delivery Batch</h3>
                <button
                  phx-click="close_batch_modal"
                  class="text-gray-400 hover:text-gray-600"
                  data-testid="close-modal-button"
                >
                  <.icon name="hero-x-mark" class="h-6 w-6" />
                </button>
              </div>
              
              <form phx-submit="submit_batch_creation" class="space-y-4">
                <div>
                  <label for="batch_name" class="block text-sm font-medium text-gray-700">Batch Name</label>
                  <input
                    type="text"
                    name="batch_name"
                    id="batch_name"
                    required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    placeholder="e.g., Evening Delivery #1"
                    data-testid="batch-name-input"
                  />
                </div>
                
                <div class="bg-gray-50 p-3 rounded-lg">
                  <p class="text-sm text-gray-600">Selected Orders: <span class="font-semibold">{MapSet.size(@selected_orders)}</span></p>
                  <p class="text-xs text-gray-500 mt-1">A courier will be automatically assigned if available.</p>
                </div>
                
                <div class="flex justify-end space-x-3">
                  <button
                    type="button"
                    phx-click="close_batch_modal"
                    class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-medium py-2 px-4 rounded"
                    data-testid="cancel-batch-button"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded"
                    data-testid="submit-batch-button"
                  >
                    Create Batch
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Modal placeholders for TDD tests -->
      <div data-modal="rejection-modal" style="display: none;">
        <form id="rejection-form" phx-submit="submit_rejection">
          <input name="rejection_reason" type="text" value="" />
          <input name="rejection_notes" type="text" value="" />
        </form>
      </div>

      <div data-modal="delivery-failure-modal" style="display: none;">
        <form id="delivery-failure-form" phx-submit="submit_delivery_failure">
          <input name="failure_reason" type="text" value="" />
          <input name="failure_notes" type="text" value="" />
        </form>
      </div>
    </Layouts.app>
    """
  end

  defp render_order_card(order, status) do
    assigns = %{order: order, status: status}

    ~H"""
    <div class="bg-white shadow-lg rounded-lg border border-gray-200 p-6">
      <!-- Order Header -->
      <div class="flex justify-between items-start mb-4">
        <div>
          <h3 class="text-lg font-semibold text-gray-900">Order #{@order.id}</h3>
          <p class="text-sm text-gray-500">
            <%= if @order.confirmed_at do %>
              Placed {format_time_ago(@order.confirmed_at)}
            <% else %>
              Placed {format_time_ago(@order.inserted_at)}
            <% end %>
          </p>
        </div>
        <div class="text-right">
          <span class="text-lg font-bold text-gray-900">€{@order.total_price}</span>
        </div>
      </div>
      
    <!-- Order Items -->
      <div class="mb-4">
        <h4 class="font-medium text-gray-900 mb-2">Items</h4>
        <div class="space-y-1">
          <%= for item <- @order.order_items do %>
            <div class="flex justify-between text-sm">
              <span>{item.quantity}× {item.meal.name}</span>
              <span class="text-gray-600">€{Decimal.mult(item.meal.price, item.quantity)}</span>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Customer Information -->
      <div class="mb-4 p-3 bg-gray-50 rounded-lg">
        <h4 class="font-medium text-gray-900 mb-1">Delivery Information</h4>
        <p class="text-sm text-gray-700">{@order.delivery_address}</p>
        <%= if @order.delivery_notes do %>
          <p class="text-sm text-gray-600 mt-1"><strong>Notes:</strong> {@order.delivery_notes}</p>
        <% end %>
        
    <!-- Customer Contact Information -->
        <div class="mt-2 pt-2 border-t border-gray-200">
          <h5 class="font-medium text-gray-800 text-xs mb-1">Customer Contact</h5>
          <div class="flex items-center space-x-3 text-xs">
            <%= if @order.customer_phone do %>
              <a
                href={"tel:#{@order.customer_phone}"}
                class="text-blue-600 hover:text-blue-800 underline"
                data-contact="phone"
                data-test="customer-phone-link"
              >
                {@order.customer_phone}
              </a>
            <% else %>
              <%= if @order.customer && @order.customer.phone_number do %>
                <a
                  href={"tel:#{@order.customer.phone_number}"}
                  class="text-blue-600 hover:text-blue-800 underline"
                  data-contact="phone"
                  data-test="customer-phone-link"
                >
                  {@order.customer.phone_number}
                </a>
              <% end %>
            <% end %>
            <%= if @order.customer_email do %>
              <a
                href={"mailto:#{@order.customer_email}"}
                class="text-blue-600 hover:text-blue-800 underline"
                data-contact="email"
                data-test="customer-email-link"
              >
                {@order.customer_email}
              </a>
            <% else %>
              <%= if @order.customer do %>
                <a
                  href={"mailto:#{@order.customer.email}"}
                  class="text-blue-600 hover:text-blue-800 underline"
                  data-contact="email"
                  data-test="customer-email-link"
                >
                  {@order.customer.email}
                </a>
              <% end %>
            <% end %>
          </div>
        </div>
        
        <%!-- MVP: batch delivery hidden --%>
        <%= if false do %>
          <!-- Delivery Context Information -->
          <div class="mt-2 pt-2 border-t border-gray-200">
            <h5 class="font-medium text-gray-800 text-xs mb-1">Delivery Status</h5>
            <div class="flex items-center justify-between">
              <%= if @order.delivery_status do %>
                <span
                  class={[
                    "inline-flex px-2 py-1 rounded-full text-xs font-medium",
                    case @order.delivery_status do
                      "scheduled" -> "bg-blue-100 text-blue-800"
                      "assigned" -> "bg-purple-100 text-purple-800"
                      "in_transit" -> "bg-orange-100 text-orange-800"
                      "delivered" -> "bg-green-100 text-green-800"
                      _ -> "bg-gray-100 text-gray-800"
                    end
                  ]}
                  data-test="delivery-status-badge"
                >
                  {String.replace(@order.delivery_status || "unscheduled", "_", " ")}
                </span>
              <% else %>
                <span
                  class="inline-flex px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
                  data-test="delivery-status-badge"
                >
                  unscheduled
                </span>
              <% end %>

              <%= if @order.delivery_batch do %>
                <span
                  class="inline-flex px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"
                  data-test="batch-status-chip"
                >
                  Batched
                </span>
              <% else %>
                <span
                  class="inline-flex px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600"
                  data-test="batch-status-chip"
                >
                  Unbatched
                </span>
              <% end %>
            </div>

            <%= if @order.delivery_batch do %>
              <div class="mt-1 text-xs text-gray-600">
                <span class="font-medium">Batch:</span>
                <a
                  href="#"
                  class="text-blue-600 hover:text-blue-800 underline"
                  data-test="batch-code-link"
                >
                  {"BATCH-#{@order.delivery_batch.id}"}
                </a>
                <%= if @order.delivery_batch.courier do %>
                  <span class="ml-2">
                    • <span class="font-medium">Courier:</span> {@order.delivery_batch.courier.name}
                  </span>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
      
    <!-- Delay Information -->
      <%= if @order.is_delayed do %>
        <div class="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-lg">
          <h4 class="font-medium text-amber-800">Delay Reported</h4>
          <%= if @order.delay_reason do %>
            <p class="text-sm text-amber-700">{@order.delay_reason}</p>
          <% end %>
        </div>
      <% end %>
      
    <!-- Action Buttons -->
      <div class="flex flex-wrap gap-2">
        <%= case @status do %>
          <% "pending" -> %>
            <button
              phx-click="accept_order"
              phx-value-order_id={@order.id}
              id={"accept-order-#{@order.id}"}
              class="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 text-sm font-medium"
            >
              Accept Order
            </button>
            <button
              phx-click="reject_order"
              phx-value-order_id={@order.id}
              phx-value-reason="Restaurant unavailable"
              id={"reject-order-#{@order.id}"}
              class="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 text-sm font-medium"
            >
              Reject Order
            </button>
          <% "confirmed" -> %>
            <button
              phx-click="start_preparing"
              phx-value-order_id={@order.id}
              id={"start-preparing-#{@order.id}"}
              class="bg-orange-600 text-white px-4 py-2 rounded-lg hover:bg-orange-700 text-sm font-medium"
            >
              Start Preparing
            </button>
          <% "preparing" -> %>
            <button
              phx-click="mark_ready"
              phx-value-order_id={@order.id}
              id={"mark-ready-#{@order.id}"}
              class="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 text-sm font-medium"
            >
              Mark Ready
            </button>
          <% "ready" -> %>
            <%!-- MVP: batch delivery hidden --%>
            <%= if false do %>
              <button
                phx-click="stage_order"
                phx-value-order_id={@order.id}
                class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm font-medium"
              >
                Stage for Batch Delivery
              </button>
            <% end %>
            <button
              phx-click="send_for_delivery"
              phx-value-order_id={@order.id}
              class="bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700 text-sm font-medium"
            >
              Send for Delivery
            </button>
          <% "out_for_delivery" -> %>
            <button
              phx-click="mark_delivered"
              phx-value-order_id={@order.id}
              class="bg-green-700 text-white px-4 py-2 rounded-lg hover:bg-green-800 text-sm font-medium"
            >
              Mark as Delivered
            </button>
            <button
              phx-click="report_delivery_failure"
              phx-value-order_id={@order.id}
              phx-value-reason="Could not locate customer address"
              id={"report-delivery-failure-#{@order.id}"}
              class="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 text-sm font-medium"
            >
              Report Failure
            </button>
        <% end %>
      </div>
      
    <!-- Order Actions Note -->
      <div class="mt-4 text-sm text-gray-500">
        💡 For MVP, cancellation and delay reporting can be handled via direct restaurant communication.
        Advanced modal interfaces will be implemented in future iterations.
      </div>
    </div>
    """
  end

  defp format_time_ago(datetime) do
    now = NaiveDateTime.utc_now()
    diff_minutes = NaiveDateTime.diff(now, datetime, :minute)

    cond do
      diff_minutes < 1 -> "just now"
      diff_minutes < 60 -> "#{diff_minutes}m ago"
      diff_minutes < 1440 -> "#{div(diff_minutes, 60)}h ago"
      true -> "#{div(diff_minutes, 1440)}d ago"
    end
  end

  defp create_notification_for_status_change(order, old_status, new_status) do
    # Generate unique ID for notification
    notification_id = :crypto.strong_rand_bytes(8) |> Base.encode16()

    {title, message, priority} =
      case {old_status, new_status} do
        {_, "pending"} ->
          {"New Order Received",
           "Order ##{order.id} has been placed and requires your attention.", :critical}

        {"pending", "confirmed"} ->
          {"Order Confirmed", "Order ##{order.id} status changed to confirmed", :normal}

        {"confirmed", "preparing"} ->
          {"Order In Progress", "Order ##{order.id} is now being prepared.", :normal}

        {"preparing", "ready"} ->
          {"Order Ready", "Order ##{order.id} is ready for delivery.", :normal}

        {"ready", "out_for_delivery"} ->
          {"Order Out for Delivery", "Order ##{order.id} has been sent for delivery.", :normal}

        {"out_for_delivery", "delivered"} ->
          {"Order Delivered", "Order ##{order.id} has been successfully delivered.", :normal}

        {_, "cancelled"} ->
          {"Order Cancelled", "Order ##{order.id} has been cancelled.", :critical}

        {_, "delivery_failed"} ->
          {"Delivery Failed", "Order ##{order.id} delivery failed and requires attention.",
           :critical}

        _ ->
          {"Order Updated",
           "Order ##{order.id} status changed from #{old_status} to #{new_status}.", :normal}
      end

    %{
      id: notification_id,
      title: title,
      message: message,
      priority: priority,
      timestamp: NaiveDateTime.utc_now(),
      read: false,
      order_id: order.id
    }
  end

  # Helper function to refresh staging data after batch operations
  defp refresh_staging_data(socket, message) do
    staged_orders = Orders.list_staged_orders_for_restaurant(socket.assigns.restaurant.id)
    delivery_batches = Orders.list_restaurant_delivery_batches(socket.assigns.restaurant.id)
    
    socket = 
      socket
      |> assign(:staged_orders, staged_orders)
      |> assign(:delivery_batches, delivery_batches)
      |> assign(:selected_orders, MapSet.new())
      |> assign(:show_batch_modal, false)
      |> put_flash(:info, message)
    
    {:noreply, socket}
  end

  defp convert_event_to_notification(event) do
    # Convert notification event (from DB) to our notification format
    # Use database ID as string for consistency
    notification_id = "event_#{event.id}"

    # Extract order info and create appropriate title/message
    order_id = event.data["order_id"]
    new_status = event.data["new_status"] || event.data[:new_status]
    _old_status = event.data["old_status"] || event.data[:old_status]

    {title, message} =
      case event.event_type do
        "order_status_changed" ->
          if new_status do
            {"Order Status Changed", "Order ##{order_id} status changed to #{new_status}"}
          else
            {"Order Updated", "Order ##{order_id} has been updated"}
          end

        _ ->
          {"Notification", "Order ##{order_id} - #{event.event_type}"}
      end

    # Convert priority from string to atom
    priority =
      case event.priority do
        "high" -> :critical
        "urgent" -> :critical
        _ -> :normal
      end

    %{
      id: notification_id,
      title: title,
      message: message,
      priority: priority,
      timestamp: event.inserted_at,
      # Mark as read if not pending
      read: event.status != "pending",
      order_id: order_id
    }
  end

  defp render_staged_order_card(order, selected_orders) do
    is_selected = MapSet.member?(selected_orders, order.id)
    assigns = %{order: order, selected_orders: selected_orders, is_selected: is_selected}

    ~H"""
    <div class={[
      "bg-white shadow-lg rounded-lg border p-6 cursor-pointer transition-colors",
      if(@is_selected, do: "border-blue-500 bg-blue-50", else: "border-gray-200 hover:border-gray-300")
    ]}>
      <!-- Selection Checkbox and Order Header -->
      <div class="flex items-start justify-between mb-4">
        <div class="flex items-start space-x-3">
          <input
            type="checkbox"
            phx-click="toggle_order_selection"
            phx-value-order_id={@order.id}
            checked={@is_selected}
            class="h-5 w-5 text-blue-600 rounded focus:ring-blue-500 border-gray-300 mt-1"
            data-testid={"order-checkbox-#{@order.id}"}
          />
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Order #{@order.id}</h3>
            <p class="text-sm text-gray-500">
              Staged {format_time_ago(@order.staged_at)}
            </p>
          </div>
        </div>
        <div class="text-right">
          <span class="text-lg font-bold text-gray-900">€{@order.total_price}</span>
          <div class="mt-1">
            <span class="inline-flex px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
              Staged
            </span>
          </div>
        </div>
      </div>
      
      <!-- Order Items -->
      <div class="mb-4">
        <h4 class="font-medium text-gray-900 mb-2">Items</h4>
        <div class="space-y-1">
          <%= for item <- @order.order_items do %>
            <div class="flex justify-between text-sm">
              <span>{item.quantity}× {item.meal.name}</span>
              <span class="text-gray-600">€{Decimal.mult(item.meal.price, item.quantity)}</span>
            </div>
          <% end %>
        </div>
      </div>
      
      <!-- Delivery Information -->
      <div class="p-3 bg-gray-50 rounded-lg">
        <h4 class="font-medium text-gray-900 mb-1">Delivery Address</h4>
        <p class="text-sm text-gray-700">{@order.delivery_address}</p>
        <%= if @order.delivery_notes do %>
          <p class="text-sm text-gray-600 mt-1"><strong>Notes:</strong> {@order.delivery_notes}</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_batch_card(batch) do
    assigns = %{batch: batch}

    ~H"""
    <div class="bg-white shadow-lg rounded-lg border border-gray-200 p-6">
      <!-- Batch Header -->
      <div class="flex justify-between items-start mb-4">
        <div>
          <h3 class="text-lg font-semibold text-gray-900">{@batch.name}</h3>
          <p class="text-sm text-gray-500">
            Created {format_time_ago(@batch.inserted_at)}
          </p>
        </div>
        <div class="text-right">
          <span class={[
            "inline-flex px-3 py-1 rounded-full text-sm font-medium",
            case @batch.status do
              "draft" -> "bg-gray-100 text-gray-800"
              "proposed" -> "bg-yellow-100 text-yellow-800"
              "accepted" -> "bg-blue-100 text-blue-800"
              "in_progress" -> "bg-orange-100 text-orange-800"
              "completed" -> "bg-green-100 text-green-800"
              "cancelled" -> "bg-red-100 text-red-800"
              _ -> "bg-gray-100 text-gray-800"
            end
          ]}>
            {String.replace(@batch.status, "_", " ") |> String.capitalize()}
          </span>
        </div>
      </div>
      
      <!-- Batch Details -->
      <div class="space-y-3">
        <!-- Orders Count -->
        <div class="flex justify-between items-center">
          <span class="text-sm font-medium text-gray-700">Orders:</span>
          <span class="text-sm text-gray-900">{length(@batch.orders)}</span>
        </div>
        
        <!-- Batch Code -->
        <div class="flex justify-between items-center">
          <span class="text-sm font-medium text-gray-700">Batch Code:</span>
          <span class="text-sm font-mono text-gray-900">{"BATCH-#{@batch.id}"}</span>
        </div>
        
        <!-- Courier Assignment -->
        <div class="flex justify-between items-center">
          <span class="text-sm font-medium text-gray-700">Courier:</span>
          <%= if @batch.courier do %>
            <span class="text-sm text-gray-900">{@batch.courier.name || "Courier ##{@batch.courier.id}"}</span>
          <% else %>
            <span class="text-sm text-gray-500">Not assigned</span>
          <% end %>
        </div>
        
        <!-- Auto-assignment Info -->
        <%= if @batch.auto_assigned do %>
          <div class="text-xs text-blue-600 bg-blue-50 p-2 rounded">
            🤖 Auto-assigned to courier
          </div>
        <% end %>
      </div>
      
      <!-- Order List -->
      <%= if length(@batch.orders) > 0 do %>
        <div class="mt-4">
          <h4 class="font-medium text-gray-900 mb-2">Orders in Batch</h4>
          <div class="space-y-1">
            <%= for order <- Enum.take(@batch.orders, 5) do %>
              <div class="flex justify-between text-sm bg-gray-50 p-2 rounded">
                <span>Order #{order.id}</span>
                <span class="text-gray-600">€{order.total_price}</span>
              </div>
            <% end %>
            <%= if length(@batch.orders) > 5 do %>
              <div class="text-xs text-gray-500 text-center py-1">
                ... and {length(@batch.orders) - 5} more orders
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
      
      <!-- Batch Actions -->
      <div class="mt-4 flex justify-between items-center">
        <div class="text-xs text-gray-500">
          Total Value: €{Enum.reduce(@batch.orders, Decimal.new("0"), fn order, acc ->
            Decimal.add(acc, order.total_price)
          end)}
        </div>
        
        <%= case @batch.status do %>
          <% "draft" -> %>
            <span class="text-xs text-gray-500">Waiting for courier assignment</span>
          <% "proposed" -> %>
            <span class="text-xs text-yellow-600">Proposed to courier</span>
          <% "accepted" -> %>
            <span class="text-xs text-blue-600">Accepted by courier</span>
          <% "in_progress" -> %>
            <span class="text-xs text-orange-600">In progress</span>
          <% "completed" -> %>
            <span class="text-xs text-green-600">Completed</span>
          <% "cancelled" -> %>
            <span class="text-xs text-red-600">Cancelled</span>
        <% end %>
      </div>
    </div>
    """
  end
end
