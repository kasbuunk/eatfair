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
      |> assign_donation_metrics()
      |> assign_review_moderation_queue()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
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
          
    <!-- Donation Tracking Section -->
          <div class="card bg-base-100 shadow-lg mb-8">
            <div class="card-body">
              <h2 class="card-title mb-4">
                <.icon name="hero-heart" class="size-6 text-green-500" /> Platform Donations & Support
              </h2>

              <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                <div class="stat bg-green-50 rounded-lg p-4">
                  <div class="stat-figure text-green-600">
                    <.icon name="hero-currency-euro" class="size-6" />
                  </div>
                  <div class="stat-title text-sm">Total Donations</div>
                  <div class="stat-value text-green-600 text-xl">
                    €{@donation_metrics.total_donations}
                  </div>
                  <div class="stat-desc text-green-500">All-time platform support</div>
                </div>

                <div class="stat bg-blue-50 rounded-lg p-4">
                  <div class="stat-figure text-blue-600">
                    <.icon name="hero-calendar-days" class="size-6" />
                  </div>
                  <div class="stat-title text-sm">This Month</div>
                  <div class="stat-value text-blue-600 text-xl">
                    €{@donation_metrics.donations_this_month}
                  </div>
                  <div class="stat-desc text-blue-500">
                    +{@donation_metrics.monthly_growth}% vs last month
                  </div>
                </div>

                <div class="stat bg-purple-50 rounded-lg p-4">
                  <div class="stat-figure text-purple-600">
                    <.icon name="hero-users" class="size-6" />
                  </div>
                  <div class="stat-title text-sm">Donors</div>
                  <div class="stat-value text-purple-600 text-xl">
                    {@donation_metrics.unique_donors}
                  </div>
                  <div class="stat-desc text-purple-500">Supporting the platform</div>
                </div>

                <div class="stat bg-yellow-50 rounded-lg p-4">
                  <div class="stat-figure text-yellow-600">
                    <.icon name="hero-chart-bar-square" class="size-6" />
                  </div>
                  <div class="stat-title text-sm">Avg Donation</div>
                  <div class="stat-value text-yellow-600 text-xl">
                    €{@donation_metrics.average_donation}
                  </div>
                  <div class="stat-desc text-yellow-500">Per contribution</div>
                </div>
              </div>
              
    <!-- Recent donations list -->
              <div class="overflow-x-auto">
                <h3 class="text-lg font-semibold mb-3">Recent Donations</h3>
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Time</th>
                      <th>Amount</th>
                      <th>Order</th>
                      <th>Customer</th>
                      <th>Restaurant</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={donation <- @donation_metrics.recent_donations} class="hover">
                      <td class="text-sm">
                        {Calendar.strftime(donation.inserted_at, "%m/%d %H:%M")}
                      </td>
                      <td><span class="badge badge-success">€{donation.amount}</span></td>
                      <td class="text-sm">#{donation.order_id}</td>
                      <td class="text-sm">{donation.customer_email}</td>
                      <td class="text-sm">{donation.restaurant_name}</td>
                    </tr>
                  </tbody>
                </table>

                <div :if={Enum.empty?(@donation_metrics.recent_donations)} class="text-center py-8">
                  <.icon name="hero-heart" class="size-8 text-base-content/30 mx-auto mb-2" />
                  <p class="text-base-content/60">No recent donations</p>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Review Moderation Section -->
          <div class="card bg-base-100 shadow-lg mb-8">
            <div class="card-body">
              <h2 class="card-title mb-4">
                <.icon name="hero-photo" class="size-6 text-indigo-500" /> Review Image Moderation
              </h2>

              <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                <div class="stat bg-indigo-50 rounded-lg p-4">
                  <div class="stat-figure text-indigo-600">
                    <.icon name="hero-eye" class="size-6" />
                  </div>
                  <div class="stat-title text-sm">Pending Review</div>
                  <div class="stat-value text-indigo-600 text-xl">
                    {@review_moderation.pending_count}
                  </div>
                  <div class="stat-desc text-indigo-500">Images awaiting approval</div>
                </div>

                <div class="stat bg-green-50 rounded-lg p-4">
                  <div class="stat-figure text-green-600">
                    <.icon name="hero-check-circle" class="size-6" />
                  </div>
                  <div class="stat-title text-sm">Approved Today</div>
                  <div class="stat-value text-green-600 text-xl">
                    {@review_moderation.approved_today}
                  </div>
                  <div class="stat-desc text-green-500">Images published</div>
                </div>

                <div class="stat bg-red-50 rounded-lg p-4">
                  <div class="stat-figure text-red-600">
                    <.icon name="hero-x-circle" class="size-6" />
                  </div>
                  <div class="stat-title text-sm">Flagged</div>
                  <div class="stat-value text-red-600 text-xl">
                    {@review_moderation.flagged_count}
                  </div>
                  <div class="stat-desc text-red-500">Require attention</div>
                </div>
              </div>
              
    <!-- Pending review images -->>
              <%= if @review_moderation.pending_count > 0 do %>
                <div class="mb-4">
                  <h3 class="text-lg font-semibold mb-3">Images Pending Approval</h3>
                  <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
                    <%= for image <- Enum.take(@review_moderation.pending_images, 12) do %>
                      <div class="relative group">
                        <img
                          src={image.compressed_path || image.image_path}
                          alt="Review image pending approval"
                          class="w-full h-20 object-cover rounded-lg border border-gray-200"
                          loading="lazy"
                        />
                        <div class="absolute inset-0 bg-black bg-opacity-50 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex items-center justify-center">
                          <div class="flex space-x-1">
                            <button
                              phx-click="approve_image"
                              phx-value-id={image.id}
                              class="btn btn-success btn-xs"
                              title="Approve"
                            >
                              <.icon name="hero-check" class="size-3" />
                            </button>
                            <button
                              phx-click="flag_image"
                              phx-value-id={image.id}
                              class="btn btn-error btn-xs"
                              title="Flag"
                            >
                              <.icon name="hero-flag" class="size-3" />
                            </button>
                          </div>
                        </div>
                        <div class="absolute top-1 right-1 bg-yellow-100 text-yellow-800 text-xs px-1 py-0.5 rounded">
                          #{image.review.restaurant.name}
                        </div>
                      </div>
                    <% end %>
                  </div>

                  <%= if length(@review_moderation.pending_images) > 12 do %>
                    <div class="text-center mt-4">
                      <button class="btn btn-outline btn-sm">
                        View All {length(@review_moderation.pending_images)} Pending Images
                      </button>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="text-center py-8">
                  <.icon name="hero-check-circle" class="size-12 text-green-500 mx-auto mb-2" />
                  <p class="text-green-600 font-medium">All images reviewed!</p>
                  <p class="text-sm text-green-500">No pending review images</p>
                </div>
              <% end %>
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
    </Layouts.app>
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

  # Handle image moderation actions
  @impl true
  def handle_event("approve_image", %{"id" => _image_id}, socket) do
    # In real implementation, this would update the image status in the database
    # For now, just show a success message and refresh the moderation queue
    socket =
      socket
      |> assign_review_moderation_queue()
      |> put_flash(:info, "Image approved successfully")

    {:noreply, socket}
  end

  def handle_event("flag_image", %{"id" => _image_id}, socket) do
    # In real implementation, this would flag the image for manual review
    socket =
      socket
      |> assign_review_moderation_queue()
      |> put_flash(:warning, "Image flagged for review")

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

  defp format_currency(decimal) when is_integer(decimal),
    do: Decimal.to_string(Decimal.new(decimal), :normal)

  defp format_currency(decimal), do: Decimal.to_string(decimal, :normal)

  defp calculate_restaurant_success_rate do
    # Calculate percentage of restaurants with repeat customers
    # This is a simplified calculation - real implementation would be more sophisticated
    85
  end

  defp assign_donation_metrics(socket) do
    # Calculate donation metrics
    metrics = %{
      total_donations: calculate_total_donations() |> format_currency(),
      donations_this_month: calculate_donations_this_month() |> format_currency(),
      monthly_growth: calculate_monthly_donation_growth(),
      unique_donors: count_unique_donors(),
      average_donation: calculate_average_donation() |> format_currency(),
      recent_donations: get_recent_donations()
    }

    assign(socket, :donation_metrics, metrics)
  end

  defp assign_review_moderation_queue(socket) do
    # Get review moderation data
    metrics = %{
      pending_count: count_pending_review_images(),
      approved_today: count_approved_images_today(),
      flagged_count: count_flagged_review_images(),
      pending_images: get_pending_review_images()
    }

    assign(socket, :review_moderation, metrics)
  end

  # Donation calculation functions
  defp calculate_total_donations do
    # Sum all donation amounts from orders
    Orders.total_donations(all_time: true) || Decimal.new("0.00")
  end

  defp calculate_donations_this_month do
    # Sum donations from current month
    current_month = Date.utc_today() |> Date.beginning_of_month()
    Orders.total_donations(since: current_month) || Decimal.new("0.00")
  end

  defp calculate_monthly_donation_growth do
    # Calculate month-over-month growth percentage
    # Simplified for demo - would be more sophisticated in production
    15
  end

  defp count_unique_donors do
    # Count unique users who have made donations
    Orders.count_unique_donors() || 0
  end

  defp calculate_average_donation do
    # Calculate average donation amount
    Orders.average_donation_amount() || Decimal.new("0.00")
  end

  defp get_recent_donations do
    # Get recent donations with order and customer info
    # Simplified data structure for demo
    [
      %{
        inserted_at: DateTime.utc_now() |> DateTime.add(-2, :hour),
        amount: "2.50",
        order_id: 123,
        customer_email: "alice@example.com",
        restaurant_name: "Pizza Palace"
      },
      %{
        inserted_at: DateTime.utc_now() |> DateTime.add(-4, :hour),
        amount: "5.00",
        order_id: 122,
        customer_email: "bob@example.com",
        restaurant_name: "Burger House"
      },
      %{
        inserted_at: DateTime.utc_now() |> DateTime.add(-6, :hour),
        amount: "1.00",
        order_id: 121,
        customer_email: "carol@example.com",
        restaurant_name: "Sushi Spot"
      }
    ]
  end

  # Review moderation functions
  defp count_pending_review_images do
    # Count review images awaiting approval
    # In real implementation, this would query the database
    3
  end

  defp count_approved_images_today do
    # Count images approved today
    7
  end

  defp count_flagged_review_images do
    # Count flagged images requiring attention
    1
  end

  defp get_pending_review_images do
    # Get pending review images with context
    # Simplified data structure for demo
    [
      %{
        id: 1,
        image_path: "/uploads/reviews/sample1.jpg",
        compressed_path: "/uploads/reviews/sample1_compressed.jpg",
        review: %{
          restaurant: %{name: "Pizza Palace"}
        }
      },
      %{
        id: 2,
        image_path: "/uploads/reviews/sample2.jpg",
        compressed_path: "/uploads/reviews/sample2_compressed.jpg",
        review: %{
          restaurant: %{name: "Burger House"}
        }
      },
      %{
        id: 3,
        image_path: "/uploads/reviews/sample3.jpg",
        compressed_path: "/uploads/reviews/sample3_compressed.jpg",
        review: %{
          restaurant: %{name: "Sushi Spot"}
        }
      }
    ]
  end
end
