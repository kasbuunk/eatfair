defmodule EatfairWeb.RestaurantOrderManagementLive do
  use EatfairWeb, :live_view
  
  alias Eatfair.{Orders, Restaurants}
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
        # Subscribe to restaurant order updates
        PubSub.subscribe(Eatfair.PubSub, "restaurant_orders:#{restaurant.id}")
        
        # Get orders grouped by status
        orders_by_status = Orders.list_restaurant_orders(restaurant.id)
        
        socket = 
          socket
          |> assign(:restaurant, restaurant)
          |> assign(:orders_by_status, orders_by_status)
          |> assign(:page_title, "Order Management - #{restaurant.name}")
          
        {:ok, socket}
    end
  end

  @impl true
  def handle_info({:order_status_updated, updated_order, _old_status}, socket) do
    # Refresh orders when status changes
    if updated_order.restaurant_id == socket.assigns.restaurant.id do
      orders_by_status = Orders.list_restaurant_orders(socket.assigns.restaurant.id)
      socket = 
        socket
        |> assign(:orders_by_status, orders_by_status)
        |> put_flash(:info, "Order ##{updated_order.id} status updated")
        
      {:noreply, socket}
    else
      {:noreply, socket}
    end
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
  def handle_event("report_delay", %{"order_id" => order_id, "reason" => reason, "extra_minutes" => extra_minutes_str}, socket) do
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
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto p-6">
      <.header>
        Order Management - <%= @restaurant.name %>
        <:subtitle>Manage all incoming orders and update their status in real-time</:subtitle>
      </.header>
      
      <!-- Order Statistics -->
      <div class="mt-6 grid grid-cols-1 md:grid-cols-4 gap-6">
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div class="flex items-center">
            <.icon name="hero-bell-alert" class="h-8 w-8 text-blue-600 mr-3"/>
            <div>
              <p class="text-sm font-medium text-blue-600">New Orders</p>
              <p class="text-2xl font-bold text-blue-900"><%= length(@orders_by_status.confirmed) %></p>
            </div>
          </div>
        </div>
        
        <div class="bg-orange-50 border border-orange-200 rounded-lg p-4">
          <div class="flex items-center">
            <.icon name="hero-fire" class="h-8 w-8 text-orange-600 mr-3"/>
            <div>
              <p class="text-sm font-medium text-orange-600">In Progress</p>
              <p class="text-2xl font-bold text-orange-900"><%= length(@orders_by_status.preparing) %></p>
            </div>
          </div>
        </div>
        
        <div class="bg-green-50 border border-green-200 rounded-lg p-4">
          <div class="flex items-center">
            <.icon name="hero-check-circle" class="h-8 w-8 text-green-600 mr-3"/>
            <div>
              <p class="text-sm font-medium text-green-600">Ready</p>
              <p class="text-2xl font-bold text-green-900"><%= length(@orders_by_status.ready) %></p>
            </div>
          </div>
        </div>
        
        <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
          <div class="flex items-center">
            <.icon name="hero-truck" class="h-8 w-8 text-purple-600 mr-3"/>
            <div>
              <p class="text-sm font-medium text-purple-600">Out for Delivery</p>
              <p class="text-2xl font-bold text-purple-900"><%= length(@orders_by_status.out_for_delivery) %></p>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Order Sections -->
      <div class="mt-8 space-y-8">
        <!-- New Orders -->
        <%= if length(@orders_by_status.confirmed) > 0 do %>
          <div>
            <h2 class="text-xl font-bold text-gray-900 mb-4">New Orders</h2>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <%= for order <- @orders_by_status.confirmed do %>
                <%= render_order_card(order, "confirmed") %>
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
                <%= render_order_card(order, "preparing") %>
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
                <%= render_order_card(order, "ready") %>
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
                <%= render_order_card(order, "out_for_delivery") %>
              <% end %>
            </div>
          </div>
        <% end %>
        
        <!-- Empty State -->
        <%= if Enum.all?(@orders_by_status, fn {_status, orders} -> length(orders) == 0 end) do %>
          <div class="text-center py-12">
            <.icon name="hero-shopping-bag" class="h-12 w-12 text-gray-400 mx-auto mb-4"/>
            <h3 class="text-lg font-medium text-gray-900 mb-2">No Active Orders</h3>
            <p class="text-gray-500">When you receive orders, they'll appear here for management.</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
  
  defp render_order_card(order, status) do
    assigns = %{order: order, status: status}
    
    ~H"""
    <div class="bg-white shadow-lg rounded-lg border border-gray-200 p-6">
      <!-- Order Header -->
      <div class="flex justify-between items-start mb-4">
        <div>
          <h3 class="text-lg font-semibold text-gray-900">Order #<%= @order.id %></h3>
          <p class="text-sm text-gray-500">
            <%= if @order.confirmed_at do %>
              Placed <%= format_time_ago(@order.confirmed_at) %>
            <% else %>
              Placed <%= format_time_ago(@order.inserted_at) %>
            <% end %>
          </p>
        </div>
        <div class="text-right">
          <span class="text-lg font-bold text-gray-900">€<%= @order.total_price %></span>
        </div>
      </div>
      
      <!-- Order Items -->
      <div class="mb-4">
        <h4 class="font-medium text-gray-900 mb-2">Items</h4>
        <div class="space-y-1">
          <%= for item <- @order.order_items do %>
            <div class="flex justify-between text-sm">
              <span><%= item.quantity %>× <%= item.meal.name %></span>
              <span class="text-gray-600">€<%= Decimal.mult(item.meal.price, item.quantity) %></span>
            </div>
          <% end %>
        </div>
      </div>
      
      <!-- Customer Information -->
      <div class="mb-4 p-3 bg-gray-50 rounded-lg">
        <h4 class="font-medium text-gray-900 mb-1">Delivery Information</h4>
        <p class="text-sm text-gray-700"><%= @order.delivery_address %></p>
        <%= if @order.delivery_notes do %>
          <p class="text-sm text-gray-600 mt-1"><strong>Notes:</strong> <%= @order.delivery_notes %></p>
        <% end %>
      </div>
      
      <!-- Delay Information -->
      <%= if @order.is_delayed do %>
        <div class="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-lg">
          <h4 class="font-medium text-amber-800">Delay Reported</h4>
          <%= if @order.delay_reason do %>
            <p class="text-sm text-amber-700"><%= @order.delay_reason %></p>
          <% end %>
        </div>
      <% end %>
      
      <!-- Action Buttons -->
      <div class="flex flex-wrap gap-2">
        <%= case @status do %>
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
end
