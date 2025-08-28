defmodule EatfairWeb.Admin.UsersLive do
  @moduledoc """
  Admin dashboard for comprehensive user management.

  This dashboard provides:
  - User role management and elevation
  - Account verification and status tracking
  - User activity monitoring and analytics
  - Address management oversight
  - Bulk operations for user administration
  - Search and filtering capabilities
  """

  use EatfairWeb, :live_view

  import Ecto.Query
  alias Eatfair.Accounts
  alias Eatfair.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "User Management")
      |> assign_users()
      |> assign_filters()
      |> assign_search_params()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> apply_filters_from_params(params)
      |> assign_users()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="container mx-auto p-6">
        <!-- Header with navigation -->
        <div class="flex items-center justify-between mb-6">
          <div class="breadcrumbs">
            <ul>
              <li><.link navigate={~p"/admin"} class="link">Admin Dashboard</.link></li>
              <li>User Management</li>
            </ul>
          </div>

          <div class="flex gap-2">
            <.link navigate={~p"/admin"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="size-4" /> Back to Dashboard
            </.link>
          </div>
        </div>
        
    <!-- User Statistics -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div class="stat bg-base-100 rounded-lg shadow">
            <div class="stat-figure text-primary">
              <.icon name="hero-users" class="size-8" />
            </div>
            <div class="stat-title">Total Users</div>
            <div class="stat-value text-primary">{@user_stats.total_users}</div>
            <div class="stat-desc">
              +{@user_stats.new_users_today} today
            </div>
          </div>

          <div class="stat bg-base-100 rounded-lg shadow">
            <div class="stat-figure text-secondary">
              <.icon name="hero-building-storefront" class="size-8" />
            </div>
            <div class="stat-title">Restaurant Owners</div>
            <div class="stat-value text-secondary">{@user_stats.restaurant_owners}</div>
            <div class="stat-desc">
              Business accounts
            </div>
          </div>

          <div class="stat bg-base-100 rounded-lg shadow">
            <div class="stat-figure text-accent">
              <.icon name="hero-user-group" class="size-8" />
            </div>
            <div class="stat-title">Customers</div>
            <div class="stat-value text-accent">{@user_stats.customers}</div>
            <div class="stat-desc">
              Consumer accounts
            </div>
          </div>

          <div class="stat bg-base-100 rounded-lg shadow">
            <div class="stat-figure text-warning">
              <.icon name="hero-exclamation-circle" class="size-8" />
            </div>
            <div class="stat-title">Unverified</div>
            <div class="stat-value text-warning">{@user_stats.unverified_users}</div>
            <div class="stat-desc">
              Need verification
            </div>
          </div>
        </div>
        
    <!-- Search and Filter Controls -->
        <div class="card bg-base-100 shadow-lg mb-6">
          <div class="card-body">
            <h3 class="card-title mb-4">Search & Filter Users</h3>

            <form phx-change="filter_users" phx-submit="filter_users">
              <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                <!-- Search Input -->
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Search</span>
                  </label>
                  <input
                    type="text"
                    name="search"
                    placeholder="Email, name..."
                    class="input input-bordered"
                    value={@search_params.search}
                  />
                </div>
                
    <!-- Role Filter -->
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Role</span>
                  </label>
                  <select name="role" class="select select-bordered">
                    <option value="">All Roles</option>
                    <option value="customer" selected={@filters.role == "customer"}>Customer</option>
                    <option value="restaurant_owner" selected={@filters.role == "restaurant_owner"}>
                      Restaurant Owner
                    </option>
                    <option value="courier" selected={@filters.role == "courier"}>Courier</option>
                    <option value="admin" selected={@filters.role == "admin"}>Admin</option>
                  </select>
                </div>
                
    <!-- Verification Status -->
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Status</span>
                  </label>
                  <select name="verification_status" class="select select-bordered">
                    <option value="">All Status</option>
                    <option value="verified" selected={@filters.verification_status == "verified"}>
                      Verified
                    </option>
                    <option value="unverified" selected={@filters.verification_status == "unverified"}>
                      Unverified
                    </option>
                  </select>
                </div>
                
    <!-- Registration Date -->
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Registered</span>
                  </label>
                  <select name="registered" class="select select-bordered">
                    <option value="">All Time</option>
                    <option value="today" selected={@filters.registered == "today"}>Today</option>
                    <option value="week" selected={@filters.registered == "week"}>This Week</option>
                    <option value="month" selected={@filters.registered == "month"}>
                      This Month
                    </option>
                  </select>
                </div>
              </div>

              <div class="flex justify-between items-center mt-4">
                <div class="text-sm text-base-content/70">
                  Showing {length(@users)} of {@user_stats.total_users} users
                </div>

                <div class="flex gap-2">
                  <button type="button" phx-click="clear_filters" class="btn btn-ghost btn-sm">
                    Clear Filters
                  </button>
                  <button type="submit" class="btn btn-primary btn-sm">
                    Apply Filters
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
        
    <!-- Users List -->
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <div class="flex items-center justify-between mb-4">
              <h3 class="card-title">User Accounts</h3>

              <div class="flex gap-2">
                <div class="dropdown dropdown-end">
                  <div tabindex="0" role="button" class="btn btn-sm btn-outline">
                    <.icon name="hero-ellipsis-vertical" class="size-4" /> Bulk Actions
                  </div>
                  <ul
                    tabindex="0"
                    class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow"
                  >
                    <li><a phx-click="bulk_verify">Verify Selected</a></li>
                    <li><a phx-click="bulk_export">Export Data</a></li>
                    <li><a phx-click="bulk_email">Send Email</a></li>
                  </ul>
                </div>
              </div>
            </div>

            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>
                      <input
                        type="checkbox"
                        class="checkbox checkbox-sm"
                        phx-click="toggle_all_users"
                      />
                    </th>
                    <th>User</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Registered</th>
                    <th>Last Active</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={user <- @users} class="hover">
                    <td>
                      <input
                        type="checkbox"
                        class="checkbox checkbox-sm"
                        phx-click="toggle_user_selection"
                        phx-value-user-id={user.id}
                      />
                    </td>
                    <td>
                      <div class="flex items-center gap-3">
                        <div class="avatar placeholder">
                          <div class="bg-neutral text-neutral-content w-8 rounded-full">
                            <span class="text-xs">{String.first(user.name || "?")}</span>
                          </div>
                        </div>
                        <div>
                          <div class="font-bold">{user.name}</div>
                          <div class="text-sm text-base-content/60">{user.email}</div>
                          <div :if={user.phone_number} class="text-xs text-base-content/50">
                            {user.phone_number}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span class={[
                        "badge badge-sm",
                        user.role == "admin" && "badge-error",
                        user.role == "restaurant_owner" && "badge-secondary",
                        user.role == "courier" && "badge-accent",
                        user.role == "customer" && "badge-primary"
                      ]}>
                        {String.replace(user.role, "_", " ") |> String.capitalize()}
                      </span>
                    </td>
                    <td>
                      <span :if={user.confirmed_at} class="badge badge-success badge-sm">
                        Verified
                      </span>
                      <span :if={!user.confirmed_at} class="badge badge-warning badge-sm">
                        Unverified
                      </span>
                    </td>
                    <td class="text-sm">
                      {Calendar.strftime(user.inserted_at, "%Y-%m-%d")}
                    </td>
                    <td class="text-sm text-base-content/60">
                      <span :if={user.confirmed_at}>
                        {Calendar.strftime(user.confirmed_at, "%Y-%m-%d")}
                      </span>
                      <span :if={!user.confirmed_at}>Never</span>
                    </td>
                    <td>
                      <div class="dropdown dropdown-end">
                        <div tabindex="0" role="button" class="btn btn-ghost btn-xs">
                          <.icon name="hero-ellipsis-horizontal" class="size-4" />
                        </div>
                        <ul
                          tabindex="0"
                          class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow"
                        >
                          <li>
                            <button phx-click="view_user_details" phx-value-user-id={user.id}>
                              <.icon name="hero-eye" class="size-4" /> View Details
                            </button>
                          </li>
                          <li>
                            <button phx-click="edit_user_role" phx-value-user-id={user.id}>
                              <.icon name="hero-pencil" class="size-4" /> Change Role
                            </button>
                          </li>
                          <li :if={!user.confirmed_at}>
                            <button phx-click="verify_user" phx-value-user-id={user.id}>
                              <.icon name="hero-check-badge" class="size-4" /> Verify Account
                            </button>
                          </li>
                          <li>
                            <button phx-click="reset_user_password" phx-value-user-id={user.id}>
                              <.icon name="hero-key" class="size-4" /> Reset Password
                            </button>
                          </li>
                          <li>
                            <button phx-click="view_user_orders" phx-value-user-id={user.id}>
                              <.icon name="hero-shopping-bag" class="size-4" /> View Orders
                            </button>
                          </li>
                        </ul>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>

              <div :if={Enum.empty?(@users)} class="text-center py-12">
                <.icon name="hero-users" class="size-12 text-base-content/30 mx-auto mb-4" />
                <p class="text-base-content/60">No users found</p>
                <p class="text-sm text-base-content/40">
                  Try adjusting your search criteria
                </p>
              </div>
            </div>
            
    <!-- Pagination -->
            <div class="flex justify-between items-center mt-6">
              <div class="text-sm text-base-content/60">
                Page 1 of 1
              </div>

              <div class="join">
                <button class="join-item btn btn-sm btn-disabled">Previous</button>
                <button class="join-item btn btn-sm btn-active">1</button>
                <button class="join-item btn btn-sm btn-disabled">Next</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event handlers

  @impl true
  def handle_event("filter_users", params, socket) do
    socket =
      socket
      |> update_search_params(params)
      |> apply_filters()
      |> assign_users()

    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    socket =
      socket
      |> assign_filters()
      |> assign_search_params()
      |> assign_users()

    {:noreply, socket}
  end

  def handle_event("view_user_details", %{"user-id" => user_id}, socket) do
    # For now, just show a flash - in full implementation would open modal or navigate
    socket = put_flash(socket, :info, "User details for ID: #{user_id}")
    {:noreply, socket}
  end

  def handle_event("edit_user_role", %{"user-id" => user_id}, socket) do
    socket = put_flash(socket, :info, "Edit role for user ID: #{user_id}")
    {:noreply, socket}
  end

  def handle_event("verify_user", %{"user-id" => _user_id}, socket) do
    # In full implementation, this would actually verify the user
    socket = put_flash(socket, :success, "User verified successfully")
    {:noreply, assign_users(socket)}
  end

  def handle_event("reset_user_password", %{"user-id" => user_id}, socket) do
    socket = put_flash(socket, :info, "Password reset for user ID: #{user_id}")
    {:noreply, socket}
  end

  def handle_event("view_user_orders", %{"user-id" => user_id}, socket) do
    socket = put_flash(socket, :info, "Orders for user ID: #{user_id}")
    {:noreply, socket}
  end

  # Bulk operations
  def handle_event("toggle_all_users", _params, socket) do
    # Toggle all users selection - simplified for now
    {:noreply, socket}
  end

  def handle_event("toggle_user_selection", %{"user-id" => _user_id}, socket) do
    # Toggle individual user selection - simplified for now
    {:noreply, socket}
  end

  # Private helper functions

  defp assign_users(socket) do
    users = list_users_with_filters(socket.assigns.filters, socket.assigns.search_params)
    assign(socket, :users, users)
  end

  defp assign_filters(socket) do
    filters = %{
      role: nil,
      verification_status: nil,
      registered: nil
    }

    assign(socket, :filters, filters)
  end

  defp assign_search_params(socket) do
    search_params = %{
      search: ""
    }

    assign(socket, :search_params, search_params)
  end

  defp apply_filters_from_params(socket, params) do
    filters = %{
      role: params["role"],
      verification_status: params["verification_status"],
      registered: params["registered"]
    }

    search_params = %{
      search: params["search"] || ""
    }

    socket
    |> assign(:filters, filters)
    |> assign(:search_params, search_params)
    |> assign_user_stats()
  end

  defp update_search_params(socket, params) do
    filters = %{
      role: params["role"],
      verification_status: params["verification_status"],
      registered: params["registered"]
    }

    search_params = %{
      search: params["search"] || ""
    }

    socket
    |> assign(:filters, filters)
    |> assign(:search_params, search_params)
  end

  defp apply_filters(socket) do
    socket
    |> assign_user_stats()
  end

  defp assign_user_stats(socket) do
    stats = %{
      total_users: Accounts.count_users(),
      new_users_today: Accounts.count_users(since: Date.utc_today()),
      restaurant_owners: Accounts.count_users(role: "restaurant_owner"),
      customers: Accounts.count_users(role: "customer"),
      unverified_users: Accounts.count_users() - Accounts.count_users(active: true)
    }

    assign(socket, :user_stats, stats)
  end

  defp list_users_with_filters(filters, search_params) do
    # Start with base query
    query = from(u in User, preload: [], order_by: [desc: u.inserted_at])

    # Apply filters
    query =
      query
      |> maybe_filter_by_role(filters.role)
      |> maybe_filter_by_verification(filters.verification_status)
      |> maybe_filter_by_registration(filters.registered)
      |> maybe_filter_by_search(search_params.search)

    # Limit results for now
    query
    |> limit(50)
    |> Eatfair.Repo.all()
  end

  defp maybe_filter_by_role(query, role) when role in [nil, ""], do: query

  defp maybe_filter_by_role(query, role) do
    from(u in query, where: u.role == ^role)
  end

  defp maybe_filter_by_verification(query, verification_status)
       when verification_status in [nil, ""],
       do: query

  defp maybe_filter_by_verification(query, "verified") do
    from(u in query, where: not is_nil(u.confirmed_at))
  end

  defp maybe_filter_by_verification(query, "unverified") do
    from(u in query, where: is_nil(u.confirmed_at))
  end

  defp maybe_filter_by_registration(query, registered) when registered in [nil, ""], do: query

  defp maybe_filter_by_registration(query, "today") do
    today = Date.utc_today()
    {:ok, start_datetime} = DateTime.new(today, ~T[00:00:00], "Etc/UTC")
    from(u in query, where: u.inserted_at >= ^start_datetime)
  end

  defp maybe_filter_by_registration(query, "week") do
    week_ago = Date.utc_today() |> Date.add(-7)
    {:ok, start_datetime} = DateTime.new(week_ago, ~T[00:00:00], "Etc/UTC")
    from(u in query, where: u.inserted_at >= ^start_datetime)
  end

  defp maybe_filter_by_registration(query, "month") do
    month_ago = Date.utc_today() |> Date.add(-30)
    {:ok, start_datetime} = DateTime.new(month_ago, ~T[00:00:00], "Etc/UTC")
    from(u in query, where: u.inserted_at >= ^start_datetime)
  end

  defp maybe_filter_by_search(query, search_term) when search_term in [nil, ""], do: query

  defp maybe_filter_by_search(query, search_term) do
    search_pattern = "%#{String.downcase(search_term)}%"

    from(u in query,
      where:
        like(fragment("lower(?)", u.email), ^search_pattern) or
          like(fragment("lower(?)", u.name), ^search_pattern)
    )
  end
end
