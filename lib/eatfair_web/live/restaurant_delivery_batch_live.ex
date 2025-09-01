defmodule EatfairWeb.RestaurantDeliveryBatchLive do
  use EatfairWeb, :live_view

  alias Eatfair.{Orders, Restaurants, Accounts}
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
          |> put_flash(:error, "You must own a restaurant to access delivery batch management")
          |> redirect(to: ~p"/restaurant/onboard")

        {:ok, socket}

      restaurant ->
        # Subscribe to restaurant batch updates
        PubSub.subscribe(Eatfair.PubSub, "restaurant_batches:#{restaurant.id}")

        # Load initial data
        batches = Orders.list_restaurant_delivery_batches(restaurant.id)
        ready_orders = get_ready_orders_for_batching(restaurant.id)
        couriers = Accounts.list_couriers()

        socket =
          socket
          |> assign(:restaurant, restaurant)
          |> assign(:batches, batches)
          |> assign(:ready_orders, ready_orders)
          |> assign(:couriers, couriers)
          |> assign(:filter_status, :all)
          |> assign(:page_title, "Delivery Batches - #{restaurant.name}")
          |> assign(:show_create_modal, false)
          |> assign(:selected_orders, MapSet.new())
          |> assign(
            :batch_form,
            to_form(%{"name" => "", "scheduled_pickup_time" => "", "courier_id" => ""})
          )

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("show_create_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_create_modal, true)
      |> assign(:selected_orders, MapSet.new())
      |> assign(
        :batch_form,
        to_form(%{"name" => "", "scheduled_pickup_time" => "", "courier_id" => ""})
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("hide_create_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_create_modal, false)
      |> assign(:selected_orders, MapSet.new())

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_order", %{"order_id" => order_id_str}, socket) do
    order_id = String.to_integer(order_id_str)
    selected_orders = socket.assigns.selected_orders

    updated_selection =
      if MapSet.member?(selected_orders, order_id) do
        MapSet.delete(selected_orders, order_id)
      else
        MapSet.put(selected_orders, order_id)
      end

    {:noreply, assign(socket, :selected_orders, updated_selection)}
  end

  @impl true
  def handle_event("create_batch", batch_params, socket) do
    restaurant = socket.assigns.restaurant
    selected_order_ids = MapSet.to_list(socket.assigns.selected_orders)

    if Enum.empty?(selected_order_ids) do
      {:noreply, put_flash(socket, :error, "Please select at least one order for the batch")}
    else
      batch_attrs = %{
        name: batch_params["name"],
        restaurant_id: restaurant.id,
        courier_id:
          if(batch_params["courier_id"] != "",
            do: String.to_integer(batch_params["courier_id"]),
            else: nil
          ),
        scheduled_pickup_time: parse_datetime(batch_params["scheduled_pickup_time"]),
        status: "draft"
      }

      case Orders.create_delivery_batch(batch_attrs) do
        {:ok, batch} ->
          case Orders.assign_orders_to_batch(batch.id, selected_order_ids) do
            {:ok, updated_batch} ->
              # Broadcast batch created event
              PubSub.broadcast(
                Eatfair.PubSub,
                "restaurant_batches:#{restaurant.id}",
                {:batch_created, updated_batch}
              )

              socket =
                socket
                |> assign(:show_create_modal, false)
                |> assign(:selected_orders, MapSet.new())
                |> put_flash(:info, "Delivery batch '#{batch.name}' created successfully!")
                |> refresh_data()

              {:noreply, socket}

            {:error, _reason} ->
              {:noreply,
               put_flash(socket, :error, "Failed to assign orders to batch. Please try again.")}
          end

        {:error, changeset} ->
          errors = Enum.map(changeset.errors, fn {field, {msg, _}} -> "#{field}: #{msg}" end)
          error_message = "Failed to create batch: " <> Enum.join(errors, ", ")
          {:noreply, put_flash(socket, :error, error_message)}
      end
    end
  end

  @impl true
  def handle_event("propose_batch", %{"batch_id" => batch_id_str}, socket) do
    batch_id = String.to_integer(batch_id_str)

    case Orders.get_delivery_batch_with_orders(batch_id) do
      batch when batch.status == "draft" ->
        case Orders.update_delivery_batch_status(batch, "proposed") do
          {:ok, updated_batch} ->
            # Broadcast to restaurant and courier
            broadcast_batch_update(updated_batch)

            socket =
              socket
              |> put_flash(:info, "Batch '#{batch.name}' has been proposed to courier")
              |> refresh_data()

            {:noreply, socket}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not propose batch. Please try again.")}
        end

      nil ->
        {:noreply, put_flash(socket, :error, "Batch not found")}

      _batch ->
        {:noreply, put_flash(socket, :error, "Batch cannot be proposed in its current status")}
    end
  end

  @impl true
  def handle_event("cancel_batch", %{"batch_id" => batch_id_str}, socket) do
    batch_id = String.to_integer(batch_id_str)

    case Orders.get_delivery_batch_with_orders(batch_id) do
      batch when batch.status in ["draft", "proposed"] ->
        case Orders.update_delivery_batch_status(batch, "cancelled") do
          {:ok, updated_batch} ->
            # Broadcast batch cancelled
            broadcast_batch_update(updated_batch)

            socket =
              socket
              |> put_flash(:info, "Batch '#{batch.name}' has been cancelled")
              |> refresh_data()

            {:noreply, socket}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not cancel batch. Please try again.")}
        end

      nil ->
        {:noreply, put_flash(socket, :error, "Batch not found")}

      _batch ->
        {:noreply, put_flash(socket, :error, "Batch cannot be cancelled in its current status")}
    end
  end

  @impl true
  def handle_event("filter_batches", %{"status" => status}, socket) do
    filter_atom = String.to_existing_atom(status)
    {:noreply, assign(socket, :filter_status, filter_atom)}
  end

  # Handle PubSub events
  @impl true
  def handle_info({:batch_created, _batch}, socket) do
    {:noreply, refresh_data(socket)}
  end

  @impl true
  def handle_info({:batch_updated, _batch}, socket) do
    {:noreply, refresh_data(socket)}
  end

  @impl true
  def handle_info({:batch_accepted, _batch}, socket) do
    socket =
      socket
      |> put_flash(:info, "A delivery batch has been accepted by a courier!")
      |> refresh_data()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:batch_declined, _batch}, socket) do
    socket =
      socket
      |> put_flash(:info, "A delivery batch was declined by the courier")
      |> refresh_data()

    {:noreply, socket}
  end

  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={assigns[:flash] || %{}} current_scope={assigns[:current_scope]}>
      <div class="max-w-7xl mx-auto p-6">
        <.header>
          🚚 Delivery Batch Management - {@restaurant.name}
          <:subtitle>Create and manage delivery batches for efficient order fulfillment</:subtitle>
          <:actions>
            <.button phx-click="show_create_modal" class="bg-green-600 hover:bg-green-700">
              <.icon name="hero-plus" class="h-4 w-4 mr-2" /> Create Batch
            </.button>
          </:actions>
        </.header>
        
    <!-- Filter Tabs -->
        <div class="mt-6">
          <div class="border-b border-gray-200">
            <nav class="-mb-px flex space-x-8" aria-label="Tabs">
              <%= for {status, label} <- [
              {:all, "All Batches"},
              {:draft, "Draft"},
              {:proposed, "Proposed"},
              {:accepted, "Accepted"},
              {:in_progress, "In Progress"},
              {:completed, "Completed"},
              {:cancelled, "Cancelled"}
            ] do %>
                <button
                  phx-click="filter_batches"
                  phx-value-status={status}
                  class={[
                    "whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm transition-colors",
                    if @filter_status == status do
                      "border-blue-500 text-blue-600"
                    else
                      "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                    end
                  ]}
                >
                  {label}
                  <span class="ml-2 bg-gray-100 text-gray-600 py-0.5 px-2.5 rounded-full text-xs font-medium">
                    {count_batches_by_status(@batches, status)}
                  </span>
                </button>
              <% end %>
            </nav>
          </div>
        </div>
        
    <!-- Delivery Batches List -->
        <div class="mt-6">
          <%= if Enum.empty?(filtered_batches(@batches, @filter_status)) do %>
            <div class="text-center py-12">
              <.icon name="hero-cube" class="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">
                <%= case @filter_status do %>
                  <% :all -> %>
                    No delivery batches created yet
                  <% status -> %>
                    No {status} batches
                <% end %>
              </h3>
              <p class="text-gray-500">
                <%= if @filter_status == :all do %>
                  Create your first delivery batch to efficiently manage order deliveries.
                <% else %>
                  Switch to "All Batches" to see batches in other statuses.
                <% end %>
              </p>
            </div>
          <% else %>
            <div class="bg-white shadow overflow-hidden sm:rounded-md">
              <ul class="divide-y divide-gray-200">
                <%= for batch <- filtered_batches(@batches, @filter_status) do %>
                  <li class="px-4 py-4">
                    <div class="flex items-center justify-between">
                      <div class="flex items-center">
                        <div class="flex-shrink-0">
                          <span class={[
                            "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                            batch_status_class(batch.status)
                          ]}>
                            {format_batch_status(batch.status)}
                          </span>
                        </div>
                        <div class="ml-4">
                          <p class="text-sm font-medium text-gray-900">
                            {batch.name}
                          </p>
                          <div class="text-sm text-gray-500">
                            <span>{length(batch.orders)} orders</span>
                            <%= if batch.courier do %>
                              <span class="ml-2">• Courier: {batch.courier.name}</span>
                            <% else %>
                              <span class="ml-2">• No courier assigned</span>
                            <% end %>
                            <%= if batch.scheduled_pickup_time do %>
                              <span class="ml-2">
                                • Pickup: {format_datetime(batch.scheduled_pickup_time)}
                              </span>
                            <% end %>
                          </div>
                          <div class="mt-1 text-xs text-gray-400">
                            Created {format_time_ago(batch.inserted_at)}
                          </div>
                        </div>
                      </div>
                      <div class="flex items-center space-x-2">
                        <%= case batch.status do %>
                          <% "draft" -> %>
                            <.button
                              phx-click="propose_batch"
                              phx-value-batch_id={batch.id}
                              class="bg-blue-600 hover:bg-blue-700 text-white text-sm px-3 py-1"
                            >
                              Propose to Courier
                            </.button>
                            <.button
                              phx-click="cancel_batch"
                              phx-value-batch_id={batch.id}
                              class="bg-gray-600 hover:bg-gray-700 text-white text-sm px-3 py-1"
                            >
                              Cancel
                            </.button>
                          <% "proposed" -> %>
                            <span class="text-sm text-blue-600 font-medium">
                              Awaiting courier response
                            </span>
                            <.button
                              phx-click="cancel_batch"
                              phx-value-batch_id={batch.id}
                              class="bg-gray-600 hover:bg-gray-700 text-white text-sm px-3 py-1"
                            >
                              Cancel
                            </.button>
                          <% "accepted" -> %>
                            <span class="text-sm text-green-600 font-medium">
                              Accepted by courier
                            </span>
                          <% "in_progress" -> %>
                            <span class="text-sm text-purple-600 font-medium">Out for delivery</span>
                          <% "completed" -> %>
                            <span class="text-sm text-gray-500">Completed</span>
                          <% "cancelled" -> %>
                            <span class="text-sm text-gray-400">Cancelled</span>
                          <% _ -> %>
                            <span class="text-sm text-gray-400">{batch.status}</span>
                        <% end %>
                      </div>
                    </div>
                    
    <!-- Order details -->
                    <%= if length(batch.orders) > 0 do %>
                      <div class="mt-3 pl-12">
                        <div class="text-sm text-gray-600">
                          <strong>Orders in this batch:</strong>
                        </div>
                        <ul class="mt-1 text-sm text-gray-500">
                          <%= for order <- Enum.take(batch.orders, 3) do %>
                            <li class="flex justify-between">
                              <span>Order #{order.id} - {order.delivery_address}</span>
                              <span class="font-medium">€{order.total_price}</span>
                            </li>
                          <% end %>
                          <%= if length(batch.orders) > 3 do %>
                            <li class="text-gray-400">
                              ...and {length(batch.orders) - 3} more orders
                            </li>
                          <% end %>
                        </ul>
                      </div>
                    <% end %>
                  </li>
                <% end %>
              </ul>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Create Batch Modal -->
      <%= if @show_create_modal do %>
        <div
          class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50"
          id="create-batch-modal"
        >
          <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white">
            <div class="mt-3">
              <div class="flex justify-between items-center mb-4">
                <h3 class="text-lg font-medium text-gray-900">Create Delivery Batch</h3>
                <button phx-click="hide_create_modal" class="text-gray-400 hover:text-gray-600">
                  <.icon name="hero-x-mark" class="h-6 w-6" />
                </button>
              </div>

              <.form for={@batch_form} phx-submit="create_batch">
                <.input field={@batch_form[:name]} type="text" label="Batch Name" required />
                <.input
                  field={@batch_form[:scheduled_pickup_time]}
                  type="datetime-local"
                  label="Scheduled Pickup Time"
                />
                <.input
                  field={@batch_form[:courier_id]}
                  type="select"
                  label="Assign Courier (Optional)"
                  options={[{"Select a courier", ""} | Enum.map(@couriers, &{&1.name, &1.id})]}
                />
                
    <!-- Ready Orders Selection -->
                <div class="mt-6">
                  <label class="text-base font-medium text-gray-900">Select Ready Orders</label>
                  <p class="text-sm text-gray-500 mb-4">Choose orders that are ready for delivery</p>

                  <%= if Enum.empty?(@ready_orders) do %>
                    <div class="text-center py-8 bg-gray-50 rounded-lg">
                      <.icon name="hero-cube" class="h-8 w-8 text-gray-400 mx-auto mb-2" />
                      <p class="text-gray-500">No orders are currently ready for delivery</p>
                      <p class="text-sm text-gray-400">
                        Orders must be in "ready" status to be added to a batch
                      </p>
                    </div>
                  <% else %>
                    <div class="max-h-64 overflow-y-auto border border-gray-300 rounded-md">
                      <%= for order <- @ready_orders do %>
                        <label class="flex items-center p-3 hover:bg-gray-50 cursor-pointer border-b border-gray-200 last:border-b-0">
                          <input
                            type="checkbox"
                            phx-click="toggle_order"
                            phx-value-order_id={order.id}
                            checked={MapSet.member?(@selected_orders, order.id)}
                            class="mr-3"
                          />
                          <div class="flex-1">
                            <div class="flex justify-between items-start">
                              <div>
                                <p class="text-sm font-medium text-gray-900">Order #{order.id}</p>
                                <p class="text-sm text-gray-600 truncate">{order.delivery_address}</p>
                                <%= if order.customer do %>
                                  <p class="text-xs text-gray-500">{order.customer.email}</p>
                                <% end %>
                              </div>
                              <div class="text-right">
                                <p class="text-sm font-semibold text-gray-900">
                                  €{order.total_price}
                                </p>
                                <p class="text-xs text-gray-500">
                                  {Enum.count(order.order_items)} items
                                </p>
                              </div>
                            </div>
                          </div>
                        </label>
                      <% end %>
                    </div>

                    <div class="mt-3 text-sm text-gray-600">
                      Selected: {MapSet.size(@selected_orders)} orders
                    </div>
                  <% end %>
                </div>

                <div class="mt-6 flex justify-end space-x-3">
                  <.button
                    type="button"
                    phx-click="hide_create_modal"
                    class="bg-gray-300 hover:bg-gray-400 text-gray-800"
                  >
                    Cancel
                  </.button>
                  <.button
                    type="submit"
                    class="bg-green-600 hover:bg-green-700 text-white"
                    disabled={Enum.empty?(@ready_orders) || MapSet.size(@selected_orders) == 0}
                  >
                    Create Batch
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  # Private helper functions

  defp get_ready_orders_for_batching(restaurant_id) do
    # Get orders that are ready and not already in a batch
    import Ecto.Query

    from(o in Eatfair.Orders.Order,
      where: o.restaurant_id == ^restaurant_id,
      where: o.status == "ready",
      where: is_nil(o.delivery_batch_id),
      preload: [:customer, order_items: :meal],
      order_by: [asc: o.ready_at]
    )
    |> Eatfair.Repo.all()
  end

  defp refresh_data(socket) do
    restaurant_id = socket.assigns.restaurant.id
    batches = Orders.list_restaurant_delivery_batches(restaurant_id)
    ready_orders = get_ready_orders_for_batching(restaurant_id)

    socket
    |> assign(:batches, batches)
    |> assign(:ready_orders, ready_orders)
  end

  defp parse_datetime(""), do: nil
  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) do
    case NaiveDateTime.from_iso8601(datetime_string <> ":00") do
      {:ok, naive_datetime} -> naive_datetime
      {:error, _} -> nil
    end
  end

  defp broadcast_batch_update(batch) do
    # Broadcast to restaurant
    PubSub.broadcast(
      Eatfair.PubSub,
      "restaurant_batches:#{batch.restaurant_id}",
      {:batch_updated, batch}
    )

    # Broadcast to courier if assigned
    if batch.courier_id do
      PubSub.broadcast(
        Eatfair.PubSub,
        "courier_batches:#{batch.courier_id}",
        {:batch_updated, batch}
      )
    end
  end

  defp count_batches_by_status(batches, :all), do: length(batches)

  defp count_batches_by_status(batches, status) do
    status_str = to_string(status)
    Enum.count(batches, &(&1.status == status_str))
  end

  defp filtered_batches(batches, :all), do: batches

  defp filtered_batches(batches, status) do
    status_str = to_string(status)
    Enum.filter(batches, &(&1.status == status_str))
  end

  defp batch_status_class("draft"), do: "bg-gray-100 text-gray-800"
  defp batch_status_class("proposed"), do: "bg-yellow-100 text-yellow-800"
  defp batch_status_class("accepted"), do: "bg-blue-100 text-blue-800"
  defp batch_status_class("in_progress"), do: "bg-purple-100 text-purple-800"
  defp batch_status_class("completed"), do: "bg-green-100 text-green-800"
  defp batch_status_class("cancelled"), do: "bg-red-100 text-red-800"
  defp batch_status_class(_), do: "bg-gray-100 text-gray-800"

  defp format_batch_status("draft"), do: "Draft"
  defp format_batch_status("proposed"), do: "Proposed"
  defp format_batch_status("accepted"), do: "Accepted"
  defp format_batch_status("in_progress"), do: "In Progress"
  defp format_batch_status("completed"), do: "Completed"
  defp format_batch_status("cancelled"), do: "Cancelled"
  defp format_batch_status(status), do: String.replace(status, "_", " ") |> String.capitalize()

  defp format_datetime(nil), do: "Not set"

  defp format_datetime(datetime) when is_struct(datetime, NaiveDateTime) do
    datetime
    |> NaiveDateTime.to_date()
    |> Date.to_string()
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
