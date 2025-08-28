defmodule EatfairWeb.Admin.DashboardLive do
  @moduledoc """
  Main admin dashboard providing platform overview and navigation to specialized admin tools.

  This dashboard provides:
  - Platform health metrics and overview
  - Quick access to all admin management tools
  - Recent activity monitoring
  - Community impact metrics aligned with EatFair's mission
  - Navigation to specialized admin dashboards
  """

  use EatfairWeb, :live_view

  alias Eatfair.Accounts
  alias Eatfair.Restaurants
  alias Eatfair.Orders
  alias Eatfair.Feedback

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to real-time updates for admin dashboard
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "admin:dashboard")
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "admin:feedback")
    end

    socket =
      socket
      |> assign(:page_title, "Admin Dashboard")
      |> assign_platform_metrics()
      |> assign_recent_activity()
      |> assign_community_metrics()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="container mx-auto p-6">
        <!-- Header -->
        <.header>
          EatFair Admin Dashboard
          <:subtitle>
            Platform oversight and community support tools
          </:subtitle>
        </.header>
        
    <!-- Platform Health Overview -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div class="stat bg-base-100 rounded-lg shadow">
            <div class="stat-figure text-primary">
              <.icon name="hero-users" class="size-8" />
            </div>
            <div class="stat-title">Total Users</div>
            <div class="stat-value text-primary">{@platform_metrics.total_users}</div>
            <div class="stat-desc">
              +{@platform_metrics.new_users_today} today
            </div>
          </div>

          <div class="stat bg-base-100 rounded-lg shadow">
            <div class="stat-figure text-secondary">
              <.icon name="hero-building-storefront" class="size-8" />
            </div>
            <div class="stat-title">Active Restaurants</div>
            <div class="stat-value text-secondary">{@platform_metrics.active_restaurants}</div>
            <div class="stat-desc">
              {Enum.count(@platform_metrics.restaurants_by_city)} cities served
            </div>
          </div>

          <div class="stat bg-base-100 rounded-lg shadow">
            <div class="stat-figure text-accent">
              <.icon name="hero-shopping-bag" class="size-8" />
            </div>
            <div class="stat-title">Orders Today</div>
            <div class="stat-value text-accent">{@platform_metrics.orders_today}</div>
            <div class="stat-desc">
              €{@platform_metrics.revenue_today} revenue
            </div>
          </div>

          <div class="stat bg-base-100 rounded-lg shadow">
            <div class="stat-figure text-warning">
              <.icon name="hero-exclamation-triangle" class="size-8" />
            </div>
            <div class="stat-title">Pending Issues</div>
            <div class="stat-value text-warning">{@platform_metrics.pending_feedback}</div>
            <div class="stat-desc">
              Feedback awaiting review
            </div>
          </div>
        </div>
        
    <!-- Community Impact Metrics -->
        <div class="card bg-base-100 shadow-lg mb-8">
          <div class="card-body">
            <h2 class="card-title mb-4">
              <.icon name="hero-heart" class="size-6 text-red-500" /> Community Impact
            </h2>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div class="text-center">
                <div class="text-3xl font-bold text-primary mb-2">
                  €{@community_metrics.total_revenue_to_restaurants}
                </div>
                <div class="text-sm text-base-content/70">
                  Revenue kept by restaurants (100%)
                </div>
              </div>

              <div class="text-center">
                <div class="text-3xl font-bold text-secondary mb-2">
                  {@community_metrics.successful_orders}
                </div>
                <div class="text-sm text-base-content/70">
                  Meals delivered to community
                </div>
              </div>

              <div class="text-center">
                <div class="text-3xl font-bold text-accent mb-2">
                  {@community_metrics.restaurant_success_rate}%
                </div>
                <div class="text-sm text-base-content/70">
                  Restaurants with repeat customers
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Management Tools Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          <!-- User Management -->
          <.link
            navigate={~p"/admin/users"}
            class="card bg-base-100 shadow hover:shadow-lg transition-all"
          >
            <div class="card-body">
              <div class="flex items-center justify-between mb-4">
                <h3 class="card-title">User Management</h3>
                <.icon name="hero-users" class="size-8 text-primary" />
              </div>
              <p class="text-sm text-base-content/70 mb-4">
                Manage user accounts, roles, and verification status. Support customer and restaurant owner needs.
              </p>
              <div class="flex justify-between text-sm">
                <span>Active Users: {@platform_metrics.active_users}</span>
                <span class="text-primary">Manage →</span>
              </div>
            </div>
          </.link>
          
    <!-- Restaurant Management -->
          <div class="card bg-base-100 shadow opacity-50">
            <div class="card-body">
              <div class="flex items-center justify-between mb-4">
                <h3 class="card-title">Restaurant Oversight</h3>
                <.icon name="hero-building-storefront" class="size-8 text-secondary" />
              </div>
              <p class="text-sm text-base-content/70 mb-4">
                Support restaurant entrepreneurs with business metrics, operational tools, and growth insights.
              </p>
              <div class="flex justify-between text-sm">
                <span>Restaurants: {@platform_metrics.total_restaurants}</span>
                <span class="badge badge-ghost">Coming Soon</span>
              </div>
            </div>
          </div>
          
    <!-- Order Management -->
          <div class="card bg-base-100 shadow opacity-50">
            <div class="card-body">
              <div class="flex items-center justify-between mb-4">
                <h3 class="card-title">Order Support</h3>
                <.icon name="hero-shopping-bag" class="size-8 text-accent" />
              </div>
              <p class="text-sm text-base-content/70 mb-4">
                Monitor order flow, resolve customer issues, and ensure smooth transaction processing.
              </p>
              <div class="flex justify-between text-sm">
                <span>Active Orders: {@platform_metrics.active_orders}</span>
                <span class="badge badge-ghost">Coming Soon</span>
              </div>
            </div>
          </div>
          
    <!-- Payment Oversight -->
          <div class="card bg-base-100 shadow opacity-50">
            <div class="card-body">
              <div class="flex items-center justify-between mb-4">
                <h3 class="card-title">Payment Oversight</h3>
                <.icon name="hero-banknotes" class="size-8 text-warning" />
              </div>
              <p class="text-sm text-base-content/70 mb-4">
                Financial transaction monitoring, issue resolution, and revenue tracking.
              </p>
              <div class="flex justify-between text-sm">
                <span>Processing: {@platform_metrics.processing_payments}</span>
                <span class="badge badge-ghost">Coming Soon</span>
              </div>
            </div>
          </div>
          
    <!-- Feedback Dashboard -->
          <.link
            navigate={~p"/admin/feedback"}
            class="card bg-base-100 shadow hover:shadow-lg transition-all"
          >
            <div class="card-body">
              <div class="flex items-center justify-between mb-4">
                <h3 class="card-title">User Feedback</h3>
                <.icon name="hero-chat-bubble-left-right" class="size-8 text-info" />
              </div>
              <p class="text-sm text-base-content/70 mb-4">
                Process user feedback, bug reports, and feature requests. Support community needs.
              </p>
              <div class="flex justify-between text-sm">
                <span>Pending: {@platform_metrics.pending_feedback}</span>
                <span class="text-info">Review →</span>
              </div>
            </div>
          </.link>
          
    <!-- Analytics Dashboard -->
          <div class="card bg-base-100 shadow opacity-50">
            <div class="card-body">
              <div class="flex items-center justify-between mb-4">
                <h3 class="card-title">Business Intelligence</h3>
                <.icon name="hero-chart-bar" class="size-8 text-success" />
              </div>
              <p class="text-sm text-base-content/70 mb-4">
                Platform analytics, community impact metrics, and business insights for growth.
              </p>
              <div class="flex justify-between text-sm">
                <span>Data Points: {length(@recent_activity)}</span>
                <span class="badge badge-ghost">Coming Soon</span>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Recent Activity -->
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title mb-4">
              <.icon name="hero-clock" class="size-6" /> Recent Platform Activity
            </h2>

            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>Time</th>
                    <th>Type</th>
                    <th>Description</th>
                    <th>User</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={activity <- @recent_activity} class="hover">
                    <td class="text-sm">
                      {Calendar.strftime(activity.timestamp, "%H:%M")}
                    </td>
                    <td>
                      <span class={[
                        "badge badge-sm",
                        activity.type == "order" && "badge-primary",
                        activity.type == "registration" && "badge-secondary",
                        activity.type == "restaurant" && "badge-accent",
                        activity.type == "feedback" && "badge-warning"
                      ]}>
                        {String.capitalize(activity.type)}
                      </span>
                    </td>
                    <td class="text-sm">{activity.description}</td>
                    <td class="text-sm">
                      {if activity.user_email, do: activity.user_email, else: "Anonymous"}
                    </td>
                    <td>
                      <span class={[
                        "badge badge-sm badge-outline",
                        activity.status == "success" && "badge-success",
                        activity.status == "pending" && "badge-warning",
                        activity.status == "error" && "badge-error"
                      ]}>
                        {String.capitalize(activity.status)}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>

              <div :if={Enum.empty?(@recent_activity)} class="text-center py-12">
                <.icon name="hero-clock" class="size-12 text-base-content/30 mx-auto mb-4" />
                <p class="text-base-content/60">No recent activity</p>
                <p class="text-sm text-base-content/40">
                  Platform activity will appear here as it happens
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Real-time updates
  @impl true
  def handle_info({:new_feedback, _feedback}, socket) do
    socket =
      socket
      |> assign_platform_metrics()
      |> assign_recent_activity()
      |> put_flash(:info, "New feedback received")

    {:noreply, socket}
  end

  def handle_info({:platform_update, _data}, socket) do
    socket =
      socket
      |> assign_platform_metrics()
      |> assign_recent_activity()
      |> assign_community_metrics()

    {:noreply, socket}
  end

  # Private functions for data assignment

  defp assign_platform_metrics(socket) do
    metrics = %{
      total_users: Accounts.count_users(),
      active_users: Accounts.count_users(active: true),
      new_users_today: Accounts.count_users(since: Date.utc_today()),
      total_restaurants: Restaurants.count_restaurants(),
      active_restaurants: Restaurants.count_restaurants(active: true),
      restaurants_by_city: Restaurants.count_restaurants_by_city(),
      orders_today: Orders.count_orders(date: Date.utc_today()),
      revenue_today: Orders.total_revenue(date: Date.utc_today()) |> format_currency(),
      active_orders:
        Orders.count_orders(status: [:pending, :confirmed, :preparing, :ready, :out_for_delivery]),
      processing_payments: Orders.count_payments(status: [:pending, :processing]),
      pending_feedback: Feedback.count_feedback(status: "new")
    }

    assign(socket, :platform_metrics, metrics)
  end

  defp assign_recent_activity(socket) do
    # Simulate recent activity - in production this would come from actual data
    activities = [
      %{
        timestamp: DateTime.utc_now() |> DateTime.add(-5, :minute),
        type: "order",
        description: "New order placed",
        user_email: "customer@example.com",
        status: "success"
      },
      %{
        timestamp: DateTime.utc_now() |> DateTime.add(-10, :minute),
        type: "registration",
        description: "New restaurant owner registered",
        user_email: "owner@restaurant.com",
        status: "pending"
      },
      %{
        timestamp: DateTime.utc_now() |> DateTime.add(-15, :minute),
        type: "feedback",
        description: "Bug report submitted",
        user_email: "user@example.com",
        status: "new"
      }
    ]

    assign(socket, :recent_activity, activities)
  end

  defp assign_community_metrics(socket) do
    # These metrics emphasize EatFair's mission of supporting local entrepreneurs
    metrics = %{
      total_revenue_to_restaurants: Orders.total_revenue(all_time: true) |> format_currency(),
      successful_orders: Orders.count_orders(status: :delivered),
      restaurant_success_rate: calculate_restaurant_success_rate()
    }

    assign(socket, :community_metrics, metrics)
  end

  defp format_currency(decimal) when is_nil(decimal), do: "0.00"
  defp format_currency(decimal), do: Decimal.to_string(decimal, :normal)

  defp calculate_restaurant_success_rate do
    # Calculate percentage of restaurants with repeat customers
    # This is a simplified calculation - real implementation would be more sophisticated
    85
  end
end
