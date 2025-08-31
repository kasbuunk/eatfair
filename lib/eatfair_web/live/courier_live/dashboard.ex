defmodule EatfairWeb.CourierLive.Dashboard do
  use EatfairWeb, :live_view
  
  alias Eatfair.Orders
  alias EatfairWeb.Layouts
  alias Phoenix.PubSub

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    # Get current courier
    courier = socket.assigns.current_scope.user
    
    if courier.role != "courier" do
      {:ok, redirect(socket, to: ~p"/")}
    else
      # Subscribe to courier-specific batch updates
      PubSub.subscribe(Eatfair.PubSub, "courier_batches:#{courier.id}")
      
      # Load delivery batches
      batches = Orders.list_courier_delivery_batches(courier.id)
      
      # Calculate statistics
      batch_counts = Orders.count_courier_batches_by_status(courier.id)
      completed_today = Orders.count_courier_completed_batches_today(courier.id)
      
      # Group batches by status for display
      batches_by_status = group_batches_by_status(batches)
      
      socket =
        socket
        |> assign(:page_title, "Courier Dashboard")
        |> assign(:courier, courier)
        |> assign(:batches, batches)
        |> assign(:batches_by_status, batches_by_status)
        |> assign(:available_count, batch_counts["proposed"] || 0)
        |> assign(:in_transit_count, batch_counts["in_progress"] || 0)
        |> assign(:completed_today, completed_today)
        |> stream(:delivery_batches, batches)

      {:ok, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("accept_batch", %{"batch_id" => batch_id}, socket) do
    batch_id = String.to_integer(batch_id)
    
    case Orders.get_delivery_batch_with_orders(batch_id) do
      batch when batch.status == "proposed" ->
        case Orders.update_delivery_batch_status(batch, "accepted") do
          {:ok, updated_batch} ->
            # Update the stream
            socket = stream_insert(socket, :delivery_batches, updated_batch)
            
            # Refresh statistics
            socket = refresh_batch_statistics(socket)
            
            {:noreply, 
             socket
             |> put_flash(:info, "Delivery batch '#{updated_batch.name}' accepted successfully!")
            }
            
          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Unable to accept batch. Please try again.")}
        end
        
      nil ->
        {:noreply, put_flash(socket, :error, "Batch not found")}
        
      _batch ->
        {:noreply, put_flash(socket, :error, "This batch is no longer available for acceptance")}
    end
  end
  
  def handle_event("decline_batch", %{"batch_id" => batch_id}, socket) do
    batch_id = String.to_integer(batch_id)
    
    case Orders.get_delivery_batch_with_orders(batch_id) do
      batch when batch.status == "proposed" ->
        case Orders.update_delivery_batch_status(batch, "draft") do
          {:ok, _updated_batch} ->
            # Remove from the stream since it's no longer available to this courier
            socket = stream_delete(socket, :delivery_batches, batch)
            
            # Refresh statistics
            socket = refresh_batch_statistics(socket)
            
            {:noreply, 
             socket
             |> put_flash(:info, "Delivery batch '#{batch.name}' declined.")
            }
            
          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Unable to decline batch. Please try again.")}
        end
        
      nil ->
        {:noreply, put_flash(socket, :error, "Batch not found")}
        
      _batch ->
        {:noreply, put_flash(socket, :error, "This batch is no longer available")}
    end
  end
  
  def handle_event("start_delivery", %{"batch_id" => batch_id}, socket) do
    batch_id = String.to_integer(batch_id)
    
    case Orders.get_delivery_batch_with_orders(batch_id) do
      batch when batch.status == "accepted" ->
        case Orders.update_delivery_batch_status(batch, "in_progress") do
          {:ok, updated_batch} ->
            socket = stream_insert(socket, :delivery_batches, updated_batch)
            socket = refresh_batch_statistics(socket)
            
            {:noreply, 
             socket
             |> put_flash(:info, "Started delivery for batch '#{updated_batch.name}'")
            }
            
          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Unable to start delivery. Please try again.")}
        end
        
      nil ->
        {:noreply, put_flash(socket, :error, "Batch not found")}
        
      _batch ->
        {:noreply, put_flash(socket, :error, "This batch cannot be started")}
    end
  end
  
  def handle_event("complete_batch", %{"batch_id" => batch_id}, socket) do
    batch_id = String.to_integer(batch_id)
    
    case Orders.get_delivery_batch_with_orders(batch_id) do
      batch when batch.status == "in_progress" ->
        case Orders.update_delivery_batch_status(batch, "completed") do
          {:ok, updated_batch} ->
            socket = stream_insert(socket, :delivery_batches, updated_batch)
            socket = refresh_batch_statistics(socket)
            
            {:noreply, 
             socket
             |> put_flash(:info, "Batch '#{updated_batch.name}' completed successfully!")
            }
            
          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Unable to complete batch. Please try again.")}
        end
        
      nil ->
        {:noreply, put_flash(socket, :error, "Batch not found")}
        
      _batch ->
        {:noreply, put_flash(socket, :error, "This batch cannot be completed")}
    end
  end
  
  # Handle PubSub broadcasts for batch updates
  @impl Phoenix.LiveView
  def handle_info({:batch_updated, updated_batch}, socket) do
    socket = stream_insert(socket, :delivery_batches, updated_batch)
    socket = refresh_batch_statistics(socket)
    {:noreply, socket}
  end
  
  def handle_info({:new_batch_assigned, new_batch}, socket) do
    socket = stream_insert(socket, :delivery_batches, new_batch)
    socket = refresh_batch_statistics(socket)
    
    {:noreply, 
     socket
     |> put_flash(:info, "New delivery batch '#{new_batch.name}' has been assigned to you!")
    }
  end
  
  # Fallback for other messages
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={assigns[:flash] || %{}} current_scope={assigns[:current_scope]}>
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900">
            🚚 Courier Dashboard
          </h1>
          <p class="mt-2 text-sm text-gray-600">
            Welcome, {@courier.name}!
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <!-- Available Deliveries Card -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <div class="w-8 h-8 bg-green-100 rounded-md flex items-center justify-center">
                    <span class="text-green-600 font-semibold">📦</span>
                  </div>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">
                      Available Deliveries
                    </dt>
                    <dd class="text-lg font-medium text-gray-900">
                      {@available_count}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
          
          <!-- In Transit Card -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <div class="w-8 h-8 bg-blue-100 rounded-md flex items-center justify-center">
                    <span class="text-blue-600 font-semibold">🚗</span>
                  </div>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">
                      In Transit
                    </dt>
                    <dd class="text-lg font-medium text-gray-900">
                      {@in_transit_count}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Completed Today Card -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <div class="w-8 h-8 bg-purple-100 rounded-md flex items-center justify-center">
                    <span class="text-purple-600 font-semibold">✅</span>
                  </div>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">
                      Completed Today
                    </dt>
                    <dd class="text-lg font-medium text-gray-900">
                      {@completed_today}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Delivery Batches Section -->
        <div class="mt-8">
          <h2 class="text-lg font-medium text-gray-900 mb-4">Delivery Batches</h2>
          
          <%= if Enum.empty?(@streams.delivery_batches) do %>
            <div class="bg-white shadow overflow-hidden sm:rounded-md">
              <div class="px-4 py-12 text-center">
                <div class="mx-auto h-12 w-12 text-gray-400">
                  <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                  </svg>
                </div>
                <h3 class="mt-2 text-sm font-medium text-gray-900">No delivery batches</h3>
                <p class="mt-1 text-sm text-gray-500">You currently have no assigned delivery batches.</p>
              </div>
            </div>
          <% else %>
            <div class="bg-white shadow overflow-hidden sm:rounded-md">
              <ul class="divide-y divide-gray-200" id="delivery-batches" phx-update="stream">
                <li :for={{dom_id, batch} <- @streams.delivery_batches} id={dom_id} class="px-4 py-4 hover:bg-gray-50">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <div class="flex-shrink-0">
                        <span class={[
                          "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                          status_badge_class(batch.status)
                        ]}>
                          {format_status(batch.status)}
                        </span>
                      </div>
                      <div class="ml-4">
                        <p class="text-sm font-medium text-gray-900">
                          {batch.name}
                        </p>
                        <p class="text-sm text-gray-500">
                          {batch.restaurant.name} • {length(batch.orders)} orders
                        </p>
                        <p class="text-xs text-gray-400">
                          <%= if batch.scheduled_pickup_time do %>
                            Pickup: {format_datetime(batch.scheduled_pickup_time)}
                          <% end %>
                        </p>
                      </div>
                    </div>
                    <div class="flex items-center space-x-2">
                      <span class="text-sm text-gray-500">
                        Est. €{calculate_estimated_earnings(batch)}
                      </span>
                      
                      <%= case batch.status do %>
                        <% "proposed" -> %>
                          <.button 
                            phx-click="accept_batch" 
                            phx-value-batch_id={batch.id}
                            class="btn btn-sm bg-green-600 hover:bg-green-700 text-white border-0"
                          >
                            Accept
                          </.button>
                          <.button 
                            phx-click="decline_batch" 
                            phx-value-batch_id={batch.id}
                            class="btn btn-sm bg-gray-600 hover:bg-gray-700 text-white border-0"
                          >
                            Decline
                          </.button>
                          
                        <% "accepted" -> %>
                          <.button 
                            phx-click="start_delivery" 
                            phx-value-batch_id={batch.id}
                            class="btn btn-sm bg-blue-600 hover:bg-blue-700 text-white border-0"
                          >
                            Start Delivery
                          </.button>
                          
                        <% "in_progress" -> %>
                          <.button 
                            phx-click="complete_batch" 
                            phx-value-batch_id={batch.id}
                            class="btn btn-sm bg-purple-600 hover:bg-purple-700 text-white border-0"
                          >
                            Mark Complete
                          </.button>
                          
                        <% "completed" -> %>
                          <span class="text-sm text-gray-500">Completed</span>
                          
                        <% _ -> %>
                          <span class="text-sm text-gray-400">{batch.status}</span>
                      <% end %>
                    </div>
                  </div>
                  
                  <!-- Order details for in_progress batches -->
                  <%= if batch.status == "in_progress" and length(batch.orders) > 0 do %>
                    <div class="mt-3 pl-12">
                      <div class="text-sm text-gray-600">
                        <strong>Delivery addresses:</strong>
                      </div>
                      <ul class="mt-1 text-sm text-gray-500">
                        <li :for={order <- Enum.take(batch.orders, 3)} class="truncate">
                          📍 {order.delivery_address}
                        </li>
                        <%= if length(batch.orders) > 3 do %>
                          <li class="text-gray-400">...and {length(batch.orders) - 3} more addresses</li>
                        <% end %>
                      </ul>
                    </div>
                  <% end %>
                </li>
              </ul>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    </Layouts.app>
    """
  end
  
  # Private helper functions
  
  defp group_batches_by_status(batches) do
    Enum.group_by(batches, & &1.status)
  end
  
  defp refresh_batch_statistics(socket) do
    courier_id = socket.assigns.courier.id
    batch_counts = Orders.count_courier_batches_by_status(courier_id)
    completed_today = Orders.count_courier_completed_batches_today(courier_id)
    
    socket
    |> assign(:available_count, batch_counts["proposed"] || 0)
    |> assign(:in_transit_count, batch_counts["in_progress"] || 0)
    |> assign(:completed_today, completed_today)
  end
  
  defp status_badge_class("proposed"), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class("accepted"), do: "bg-blue-100 text-blue-800"
  defp status_badge_class("scheduled"), do: "bg-indigo-100 text-indigo-800"
  defp status_badge_class("in_progress"), do: "bg-purple-100 text-purple-800"
  defp status_badge_class("completed"), do: "bg-green-100 text-green-800"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800"
  
  defp format_status("proposed"), do: "Available"
  defp format_status("accepted"), do: "Accepted"
  defp format_status("scheduled"), do: "Scheduled"
  defp format_status("in_progress"), do: "In Progress"
  defp format_status("completed"), do: "Completed"
  defp format_status(status), do: String.replace(status, "_", " ") |> String.capitalize()
  
  defp format_datetime(nil), do: "Not set"
  defp format_datetime(datetime) do
    datetime
    |> NaiveDateTime.to_date()
    |> Date.to_string()
  end
  
  defp calculate_estimated_earnings(batch) do
    # Simple calculation: €2.50 base + €1.50 per order
    base_fee = 2.50
    per_order_fee = 1.50
    order_count = length(batch.orders)
    
    (base_fee + (per_order_fee * order_count))
    |> Float.round(2)
  end
end
