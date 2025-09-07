defmodule EatfairWeb.UserLive.Dashboard do
  @moduledoc """
  Consumer Personal Dashboard - comprehensive user dashboard showing:
  - Order history with donation details
  - Donation impact metrics
  - Review gallery with CRUD operations
  - Real-time updates via PubSub
  - Personal impact metrics
  """

  use EatfairWeb, :live_view

  import Ecto.Query, warn: false
  alias Eatfair.Orders
  alias Eatfair.Reviews.ReviewImage

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to real-time updates for user's data
      user_id = socket.assigns.current_scope.user.id
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "user_orders:#{user_id}")
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "donations:new:#{user_id}")
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "reviews:approved:#{user_id}")
    end

    socket =
      socket
      |> assign(:page_title, "My Dashboard")
      |> assign(:status_filter, nil)
      |> assign(:section, :orders)
      |> load_dashboard_data()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, handle_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="min-h-screen bg-gray-50 dark:bg-gray-900 transition-colors duration-200"
      role="main"
      aria-label="User dashboard"
    >
      <div class="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Header Section -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100">
            My Dashboard
          </h1>
          <p class="mt-2 text-gray-600 dark:text-gray-400">
            Welcome back, {@current_scope.user.email}
          </p>
        </div>
        
    <!-- Quick Stats Overview -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div
            class="stat bg-white dark:bg-gray-800 rounded-lg shadow p-6"
            role="region"
            aria-label="Total donations"
          >
            <div class="stat-figure text-green-600">
              <.icon name="hero-heart" class="size-8" />
            </div>
            <div class="stat-title text-sm font-medium text-gray-500 dark:text-gray-400">
              Total Donations
            </div>
            <div class="stat-value text-2xl font-bold text-green-600">
              €{@donation_metrics.total_donations}
            </div>
            <div class="stat-desc text-green-500 text-sm">Supporting local restaurants</div>
          </div>

          <div
            class="stat bg-white dark:bg-gray-800 rounded-lg shadow p-6"
            role="region"
            aria-label="Restaurants supported"
          >
            <div class="stat-figure text-blue-600">
              <.icon name="hero-building-storefront" class="size-8" />
            </div>
            <div class="stat-title text-sm font-medium text-gray-500 dark:text-gray-400">
              Restaurants Supported
            </div>
            <div class="stat-value text-2xl font-bold text-blue-600">
              {@impact_metrics.restaurants_supported}
            </div>
            <div class="stat-desc text-blue-500 text-sm">
              <%= if @impact_metrics.restaurants_supported == 1 do %>
                1 restaurant supported
              <% else %>
                {@impact_metrics.restaurants_supported} restaurants supported
              <% end %>
            </div>
          </div>

          <div
            class="stat bg-white dark:bg-gray-800 rounded-lg shadow p-6"
            role="region"
            aria-label="Reviews written"
          >
            <div class="stat-figure text-purple-600">
              <.icon name="hero-star" class="size-8" />
            </div>
            <div class="stat-title text-sm font-medium text-gray-500 dark:text-gray-400">
              Reviews Written
            </div>
            <div class="stat-value text-2xl font-bold text-purple-600">
              {@impact_metrics.reviews_written}
            </div>
            <div class="stat-desc text-purple-500 text-sm">
              {pluralize(@impact_metrics.reviews_written, "review")} written
            </div>
          </div>

          <div
            class="stat bg-white dark:bg-gray-800 rounded-lg shadow p-6"
            role="region"
            aria-label="Photos shared"
          >
            <div class="stat-figure text-orange-600">
              <.icon name="hero-photo" class="size-8" />
            </div>
            <div class="stat-title text-sm font-medium text-gray-500 dark:text-gray-400">
              Photos Shared
            </div>
            <div class="stat-value text-2xl font-bold text-orange-600">
              {@impact_metrics.photos_shared}
            </div>
            <div class="stat-desc text-orange-500 text-sm">
              {pluralize(@impact_metrics.photos_shared, "photo")} shared
            </div>
          </div>
        </div>
        
    <!-- Navigation Tabs -->
        <div class="mb-8">
          <div class="border-b border-gray-200 dark:border-gray-700">
            <nav class="-mb-px flex space-x-8" aria-label="Dashboard sections">
              <button
                phx-click="change_section"
                phx-value-section="orders"
                class={[
                  "py-2 px-1 border-b-2 font-medium text-sm transition-colors",
                  (@section == :orders && "border-indigo-500 text-indigo-600") ||
                    "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                ]}
                tabindex="0"
                accesskey="1"
              >
                Order History
              </button>
              <button
                phx-click="change_section"
                phx-value-section="reviews"
                class={[
                  "py-2 px-1 border-b-2 font-medium text-sm transition-colors",
                  (@section == :reviews && "border-indigo-500 text-indigo-600") ||
                    "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                ]}
                tabindex="0"
                accesskey="2"
              >
                My Reviews
              </button>
              <button
                phx-click="change_section"
                phx-value-section="impact"
                class={[
                  "py-2 px-1 border-b-2 font-medium text-sm transition-colors",
                  (@section == :impact && "border-indigo-500 text-indigo-600") ||
                    "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                ]}
                tabindex="0"
                accesskey="3"
              >
                Community Impact
              </button>
            </nav>
          </div>
        </div>
        
    <!-- Section Content -->
        <div class="space-y-8">
          <%= case @section do %>
            <% :orders -> %>
              <.order_history_section
                orders={@orders}
                status_filter={@status_filter}
                donation_metrics={@donation_metrics}
              />
            <% :reviews -> %>
              <.review_gallery_section reviews={@reviews} />
            <% :impact -> %>
              <.impact_metrics_section
                donation_metrics={@donation_metrics}
                impact_metrics={@impact_metrics}
              />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Order History Section Component
  attr :orders, :list, required: true
  attr :status_filter, :string
  attr :donation_metrics, :map, required: true

  def order_history_section(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow">
      <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
        <div class="flex justify-between items-center">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Order History</h2>
          <select
            data-test-id="status-filter"
            phx-change="filter_orders"
            phx-click="filter_orders"
            class="rounded-md border-gray-300 text-sm"
          >
            <option value="">All orders</option>
            <option value="delivered">Delivered</option>
            <option value="pending">Pending</option>
            <option value="confirmed">Confirmed</option>
          </select>
        </div>
      </div>

      <div class="p-6">
        <%= if Enum.any?(@orders) do %>
          <div class="space-y-4">
            <div
              :for={order <- @orders}
              data-test-id={"order-#{order.id}"}
              class="border border-gray-200 dark:border-gray-700 rounded-lg p-4"
            >
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <div class="flex items-center space-x-4">
                    <h3 class="font-medium text-gray-900 dark:text-gray-100">
                      {order.restaurant.name}
                    </h3>
                    <%= if order.donation_amount && Decimal.gt?(order.donation_amount, 0) do %>
                      <span
                        data-test-id="donation-badge"
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
                      >
                        <.icon name="hero-heart" class="size-3 mr-1" />
                        €{:erlang.float_to_binary(Decimal.to_float(order.donation_amount), [
                          {:decimals, 2}
                        ])} donated
                      </span>
                    <% end %>
                  </div>
                  <div class="text-sm text-gray-500 mt-1">
                    Order #{order.id} • {Calendar.strftime(order.inserted_at, "%B %d, %Y")}
                  </div>
                  <div class="text-sm font-medium text-gray-900 dark:text-gray-100 mt-2">
                    Total: €{:erlang.float_to_binary(Decimal.to_float(order.total_price), [
                      {:decimals, 2}
                    ])}
                  </div>
                </div>
                <span class={[
                  "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                  order.status == "delivered" && "bg-green-100 text-green-800",
                  order.status == "pending" && "bg-yellow-100 text-yellow-800",
                  order.status == "confirmed" && "bg-blue-100 text-blue-800"
                ]}>
                  {String.replace(order.status, "_", " ") |> String.capitalize()}
                </span>
              </div>
            </div>
          </div>
        <% else %>
          <%= if @status_filter do %>
            <p class="text-center text-gray-500 py-8">No {@status_filter} orders found.</p>
          <% else %>
            <div class="text-center py-12">
              <.icon name="hero-shopping-bag" class="size-12 text-gray-400 mx-auto mb-4" />
              <p class="text-gray-500 mb-2">You haven't placed any orders yet.</p>
              <.link navigate={~p"/restaurants"} class="text-indigo-600 hover:text-indigo-500">
                Browse restaurants →
              </.link>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # Review Gallery Section Component  
  attr :reviews, :list, required: true

  def review_gallery_section(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow">
      <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
        <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">My Reviews</h2>
      </div>

      <div class="p-6">
        <%= if Enum.any?(@reviews) do %>
          <div class="space-y-6">
            <div
              :for={review <- @reviews}
              class="border border-gray-200 dark:border-gray-700 rounded-lg p-4"
            >
              <div class="flex justify-between items-start mb-4">
                <div class="flex-1">
                  <h3 class="font-medium text-gray-900 dark:text-gray-100">
                    {review.restaurant.name}
                  </h3>
                  <div class="flex items-center mt-1">
                    <div class="flex text-yellow-400">
                      <%= for _star <- 1..review.rating do %>
                        ★
                      <% end %>
                      <%= if review.rating < 5 do %>
                        <%= for _star <- (review.rating + 1)..5 do %>
                          ☆
                        <% end %>
                      <% end %>
                    </div>
                    <span class="ml-2 text-sm text-gray-500">
                      {Calendar.strftime(review.inserted_at, "%B %d, %Y")}
                    </span>
                  </div>
                </div>
                <%= if review_editable?(review) do %>
                  <button
                    data-test-id={"edit-review-#{review.id}"}
                    phx-click="edit_review"
                    phx-value-id={review.id}
                    class="text-indigo-600 hover:text-indigo-500 text-sm font-medium"
                  >
                    Edit
                  </button>
                <% end %>
              </div>

              <%= if review.comment do %>
                <p class="text-gray-700 dark:text-gray-300 mb-4">{review.comment}</p>
              <% end %>

              <%= if Enum.any?(review.review_images) do %>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-2">
                  <img
                    :for={image <- review.review_images}
                    src={image.compressed_path || image.image_path}
                    alt="Review image"
                    class="w-full h-20 object-cover rounded-lg border border-gray-200"
                    loading="lazy"
                  />
                </div>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="text-center py-12">
            <.icon name="hero-star" class="size-12 text-gray-400 mx-auto mb-4" />
            <p class="text-gray-500 mb-2">You haven't written any reviews yet.</p>
            <p class="text-sm text-gray-400 mb-4">Start supporting local restaurants</p>
            <.link navigate={~p"/restaurants"} class="text-indigo-600 hover:text-indigo-500">
              Find restaurants →
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Impact Metrics Section Component
  attr :donation_metrics, :map, required: true
  attr :impact_metrics, :map, required: true

  def impact_metrics_section(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow">
      <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
        <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Community Impact</h2>
      </div>

      <div class="p-6">
        <div class="text-center">
          <%= if @donation_metrics.total_donations == "0.00" && @impact_metrics.restaurants_supported == 0 do %>
            <.icon name="hero-heart" class="size-16 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
              Start supporting local restaurants
            </h3>
            <p class="text-gray-500 mb-6">
              Your contributions help maintain EatFair's zero-commission model
            </p>
            <.link
              navigate={~p"/restaurants"}
              class="bg-indigo-600 text-white px-6 py-2 rounded-md hover:bg-indigo-700 transition-colors"
            >
              Find restaurants to support
            </.link>
          <% else %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div class="text-center">
                <div class="text-3xl font-bold text-green-600 mb-2">
                  €{@donation_metrics.total_donations}
                </div>
                <div class="text-gray-500">Total donated to support the platform</div>
              </div>

              <div class="text-center">
                <div class="text-3xl font-bold text-blue-600 mb-2">
                  {@impact_metrics.restaurants_supported}
                </div>
                <div class="text-gray-500">
                  <%= if @impact_metrics.restaurants_supported == 1 do %>
                    restaurant supported
                  <% else %>
                    restaurants supported
                  <% end %>
                </div>
              </div>
            </div>

            <div class="mt-8 p-4 bg-green-50 dark:bg-green-900 rounded-lg">
              <p class="text-green-800 dark:text-green-200 text-center">
                You've supported {@impact_metrics.restaurants_supported}
                {if @impact_metrics.restaurants_supported == 1, do: "restaurant", else: "restaurants"} with €{@donation_metrics.total_donations} in donations
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Event handlers

  @impl true
  def handle_event("change_section", %{"section" => section}, socket) do
    {:noreply, assign(socket, :section, String.to_existing_atom(section))}
  end

  def handle_event("filter_orders", %{"value" => status}, socket) do
    status_filter = if status == "", do: nil, else: status
    orders = load_filtered_orders(socket.assigns.current_scope.user.id, status_filter)

    socket =
      socket
      |> assign(:status_filter, status_filter)
      |> assign(:orders, orders)

    {:noreply, socket}
  end

  # Handle click events on the filter dropdown (for tests)
  def handle_event("filter_orders", %{"status" => status}, socket) do
    handle_event("filter_orders", %{"value" => status}, socket)
  end

  def handle_event("edit_review", %{"id" => review_id}, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/users/dashboard?action=edit_review&review_id=#{review_id}")}
  end

  # Real-time updates
  @impl true
  def handle_info({:order_status_updated, order_id, new_status}, socket) do
    orders = update_order_status_in_list(socket.assigns.orders, order_id, new_status)
    {:noreply, assign(socket, :orders, orders)}
  end

  def handle_info({:donation_processed, donation_data}, socket) do
    # Update the donation metrics directly with the new donation data
    current_donations = socket.assigns.donation_metrics.total_donations
    current_donations_decimal = Decimal.new(current_donations)
    amount = donation_data.amount || Decimal.new("0.00")

    # Add the new donation to existing total
    new_total = Decimal.add(current_donations_decimal, amount)
    new_total_str = Decimal.to_string(new_total)

    # Update metrics
    donation_metrics = %{total_donations: new_total_str}

    # Also reload the impact metrics
    socket =
      socket
      |> assign(:donation_metrics, donation_metrics)
      |> load_impact_metrics()

    {:noreply, socket}
  end

  def handle_info({:review_approved, _review_data}, socket) do
    socket = load_reviews(socket)
    {:noreply, socket}
  end

  # Private helper functions

  defp handle_action(socket, :index, _params) do
    socket
  end

  defp load_dashboard_data(socket) do
    user_id = socket.assigns.current_scope.user.id

    socket
    |> load_orders(user_id)
    |> load_donation_metrics()
    |> load_reviews()
    |> load_impact_metrics()
  end

  defp load_orders(socket, user_id) do
    orders = load_filtered_orders(user_id, socket.assigns.status_filter)
    assign(socket, :orders, orders)
  end

  defp load_filtered_orders(user_id, status_filter) do
    query_opts = [customer: user_id]
    _query_opts = if status_filter, do: [{:status, status_filter} | query_opts], else: query_opts

    # Get orders with preloaded restaurant data
    Orders.list_customer_orders(user_id)
    |> Enum.filter(fn order ->
      case status_filter do
        nil -> true
        filter -> order.status == filter
      end
    end)
  end

  defp load_donation_metrics(socket) do
    user_id = socket.assigns.current_scope.user.id

    # Calculate total donations from user's orders
    total_donations =
      Orders.list_customer_orders(user_id)
      |> Enum.filter(fn order -> order.status == "delivered" end)
      |> Enum.reduce(Decimal.new("0.00"), fn order, acc ->
        if order.donation_amount do
          Decimal.add(acc, order.donation_amount)
        else
          acc
        end
      end)
      |> Decimal.to_string(:normal)

    donation_metrics = %{
      total_donations: total_donations
    }

    assign(socket, :donation_metrics, donation_metrics)
  end

  defp load_reviews(socket) do
    user_id = socket.assigns.current_scope.user.id

    reviews =
      from(r in Eatfair.Reviews.Review,
        where: r.user_id == ^user_id,
        order_by: [desc: r.inserted_at],
        preload: [:restaurant, :review_images]
      )
      |> Eatfair.Repo.all()

    assign(socket, :reviews, reviews)
  end

  defp load_impact_metrics(socket) do
    user_id = socket.assigns.current_scope.user.id

    # Count unique restaurants from delivered orders
    restaurants_supported =
      Orders.list_customer_orders(user_id)
      |> Enum.filter(fn order -> order.status == "delivered" end)
      |> Enum.map(fn order -> order.restaurant_id end)
      |> Enum.uniq()
      |> length()

    # Count reviews written
    reviews_written =
      from(r in Eatfair.Reviews.Review, where: r.user_id == ^user_id)
      |> Eatfair.Repo.aggregate(:count)

    # Count photos shared
    photos_shared =
      from(ri in ReviewImage,
        join: r in Eatfair.Reviews.Review,
        on: ri.review_id == r.id,
        where: r.user_id == ^user_id
      )
      |> Eatfair.Repo.aggregate(:count)

    impact_metrics = %{
      restaurants_supported: restaurants_supported,
      reviews_written: reviews_written,
      photos_shared: photos_shared
    }

    assign(socket, :impact_metrics, impact_metrics)
  end

  defp review_editable?(review) do
    # Allow editing within 7 days
    cutoff = DateTime.utc_now() |> DateTime.add(-7, :day)
    DateTime.after?(review.inserted_at, cutoff)
  end

  defp update_order_status_in_list(orders, order_id, new_status) do
    Enum.map(orders, fn order ->
      if order.id == order_id do
        %{order | status: new_status}
      else
        order
      end
    end)
  end

  defp pluralize(count, singular, plural \\ nil) do
    plural = plural || singular <> "s"
    if count == 1, do: "#{count} #{singular}", else: "#{count} #{plural}"
  end
end
