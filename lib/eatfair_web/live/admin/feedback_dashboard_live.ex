defmodule EatfairWeb.Admin.FeedbackDashboardLive do
  @moduledoc """
  Admin dashboard for managing user feedback with observability features.

  This dashboard provides:
  - List of all user feedback with request_id correlation
  - Real-time updates via Phoenix PubSub
  - Request ID lookup for log correlation
  - Email notifications for new feedback
  - Placeholders for future analytics features
  """

  use EatfairWeb, :live_view
  alias Eatfair.Feedback

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "admin:feedback")
    end

    socket =
      socket
      |> assign(:feedback_list, Feedback.list_user_feedback())
      |> assign(:stats, Feedback.get_feedback_stats())
      |> assign(:selected_feedback, nil)
      |> assign(:request_id_search, "")
      |> assign(:filter_status, "all")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-base-200">
        <div class="container mx-auto p-6">
          <.header>
            Admin Feedback Dashboard
            <:subtitle>
              Manage user feedback and correlate with application logs for development troubleshooting
            </:subtitle>
          </.header>
          
    <!-- Stats Overview -->
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div class="stat bg-base-100 rounded-lg">
              <div class="stat-title">Total Feedback</div>
              <div class="stat-value text-primary">{@stats.total}</div>
              <div class="stat-desc">All time submissions</div>
            </div>
            <div class="stat bg-base-100 rounded-lg">
              <div class="stat-title">New Items</div>
              <div class="stat-value text-warning">{@stats.new}</div>
              <div class="stat-desc">Awaiting review</div>
            </div>
            <div class="stat bg-base-100 rounded-lg">
              <div class="stat-title">In Progress</div>
              <div class="stat-value text-info">{@stats.in_progress}</div>
              <div class="stat-desc">Being addressed</div>
            </div>
            <div class="stat bg-base-100 rounded-lg">
              <div class="stat-title">Resolved</div>
              <div class="stat-value text-success">{@stats.resolved}</div>
              <div class="stat-desc">Completed items</div>
            </div>
          </div>
          
    <!-- Future Analytics Placeholders -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
            <!-- Feedback Trends Placeholder -->
            <div class="card bg-base-100 shadow-lg">
              <div class="card-body">
                <h3 class="card-title">Feedback Trends</h3>
                <div class="flex items-center justify-center h-32 bg-base-200 rounded">
                  <span class="text-base-content/60">📈 Chart placeholder - Coming Soon</span>
                </div>
                <p class="text-sm text-base-content/70">
                  Weekly feedback volume and resolution trends
                </p>
              </div>
            </div>
            
    <!-- Common Issues Placeholder -->
            <div class="card bg-base-100 shadow-lg">
              <div class="card-body">
                <h3 class="card-title">Common Issues</h3>
                <div class="flex items-center justify-center h-32 bg-base-200 rounded">
                  <span class="text-base-content/60">🏷️ Categories placeholder - Coming Soon</span>
                </div>
                <p class="text-sm text-base-content/70">
                  Most reported feedback types and resolution patterns
                </p>
              </div>
            </div>
          </div>
          
    <!-- Search and Filters -->
          <div class="card bg-base-100 shadow-lg mb-6">
            <div class="card-body">
              <h3 class="card-title mb-4">Search & Filter</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Search by Request ID</span>
                  </label>
                  <input
                    type="text"
                    placeholder="Enter request ID for log correlation..."
                    class="input input-bordered"
                    phx-blur="search_request_id"
                    phx-value-query={@request_id_search}
                  />
                  <label class="label">
                    <span class="label-text-alt">
                      Find feedback associated with specific request logs
                    </span>
                  </label>
                </div>
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Filter by Status</span>
                  </label>
                  <select class="select select-bordered" phx-change="filter_status">
                    <option value="all" selected={@filter_status == "all"}>All Status</option>
                    <option value="new" selected={@filter_status == "new"}>New</option>
                    <option value="in_progress" selected={@filter_status == "in_progress"}>
                      In Progress
                    </option>
                    <option value="resolved" selected={@filter_status == "resolved"}>Resolved</option>
                    <option value="dismissed" selected={@filter_status == "dismissed"}>
                      Dismissed
                    </option>
                  </select>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Feedback List -->
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h3 class="card-title">Feedback Items</h3>

              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th>Type</th>
                      <th>Message</th>
                      <th>User</th>
                      <th>Page</th>
                      <th>Request ID</th>
                      <th>Version</th>
                      <th>Status</th>
                      <th>Date</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={feedback <- @feedback_list} class="hover">
                      <td>
                        <span class={[
                          "badge",
                          feedback.feedback_type == "bug_report" && "badge-error",
                          feedback.feedback_type == "feature_request" && "badge-info",
                          feedback.feedback_type == "general_feedback" && "badge-success",
                          feedback.feedback_type == "usability_issue" && "badge-warning"
                        ]}>
                          {String.replace(feedback.feedback_type, "_", " ") |> String.capitalize()}
                        </span>
                      </td>
                      <td class="max-w-xs">
                        <div class="truncate" title={feedback.message}>
                          {feedback.message}
                        </div>
                      </td>
                      <td>
                        {if feedback.user do
                          feedback.user.email
                        else
                          "Anonymous"
                        end}
                      </td>
                      <td class="max-w-xs">
                        <code class="text-xs bg-base-200 px-1 rounded truncate">
                          {feedback.page_url || "N/A"}
                        </code>
                      </td>
                      <td>
                        <code class="text-xs bg-base-200 px-1 rounded">
                          {feedback.request_id || "N/A"}
                        </code>
                      </td>
                      <td>
                        <span class="badge badge-outline badge-sm">
                          {feedback.version}
                        </span>
                      </td>
                      <td>
                        <span class={[
                          "badge badge-sm",
                          feedback.status == "new" && "badge-warning",
                          feedback.status == "in_progress" && "badge-info",
                          feedback.status == "resolved" && "badge-success",
                          feedback.status == "dismissed" && "badge-error"
                        ]}>
                          {String.replace(feedback.status, "_", " ") |> String.capitalize()}
                        </span>
                      </td>
                      <td class="text-sm">
                        {Calendar.strftime(feedback.inserted_at, "%Y-%m-%d %H:%M")}
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
                              <button phx-click="view_details" phx-value-id={feedback.id}>
                                <.icon name="hero-eye" class="size-4" /> View Details
                              </button>
                            </li>
                            <li>
                              <button
                                phx-click="update_status"
                                phx-value-id={feedback.id}
                                phx-value-status="in_progress"
                              >
                                <.icon name="hero-play" class="size-4" /> Start Progress
                              </button>
                            </li>
                            <li>
                              <button
                                phx-click="update_status"
                                phx-value-id={feedback.id}
                                phx-value-status="resolved"
                              >
                                <.icon name="hero-check" class="size-4" /> Mark Resolved
                              </button>
                            </li>
                          </ul>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>

                <div :if={Enum.empty?(@feedback_list)} class="text-center py-12">
                  <.icon name="hero-inbox" class="size-12 text-base-content/30 mx-auto mb-4" />
                  <p class="text-base-content/60">No feedback items found</p>
                  <p class="text-sm text-base-content/40">
                    User feedback will appear here once submitted
                  </p>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Future Features Placeholders -->
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6">
            <div class="card bg-base-100 shadow-lg">
              <div class="card-body">
                <h4 class="card-title text-base">Usage Analytics</h4>
                <div class="flex items-center justify-center h-20 bg-base-200 rounded">
                  <span class="text-sm text-base-content/60">Coming Soon</span>
                </div>
              </div>
            </div>
            <div class="card bg-base-100 shadow-lg">
              <div class="card-body">
                <h4 class="card-title text-base">Performance Metrics</h4>
                <div class="flex items-center justify-center h-20 bg-base-200 rounded">
                  <span class="text-sm text-base-content/60">Coming Soon</span>
                </div>
              </div>
            </div>
            <div class="card bg-base-100 shadow-lg">
              <div class="card-body">
                <h4 class="card-title text-base">User Satisfaction</h4>
                <div class="flex items-center justify-center h-20 bg-base-200 rounded">
                  <span class="text-sm text-base-content/60">Coming Soon</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("search_request_id", %{"query" => query}, socket) do
    feedback_list =
      if query && String.trim(query) != "" do
        Feedback.get_feedback_by_request_id(String.trim(query))
      else
        Feedback.list_user_feedback()
      end

    {:noreply, assign(socket, :feedback_list, feedback_list)}
  end

  def handle_event("filter_status", %{"value" => status}, socket) do
    feedback_list =
      if status == "all" do
        Feedback.list_user_feedback()
      else
        Feedback.list_user_feedback(status: status)
      end

    {:noreply,
     socket
     |> assign(:feedback_list, feedback_list)
     |> assign(:filter_status, status)}
  end

  def handle_event("view_details", %{"id" => feedback_id}, socket) do
    feedback = Feedback.get_user_feedback(feedback_id)
    {:noreply, assign(socket, :selected_feedback, feedback)}
  end

  def handle_event("update_status", %{"id" => feedback_id, "status" => status}, socket) do
    feedback = Feedback.get_user_feedback!(feedback_id)

    case Feedback.update_feedback_status(feedback, %{status: status}) do
      {:ok, _updated_feedback} ->
        socket =
          socket
          |> put_flash(:info, "Feedback status updated successfully")
          |> assign(:feedback_list, Feedback.list_user_feedback())
          |> assign(:stats, Feedback.get_feedback_stats())

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update feedback status")}
    end
  end

  @impl true
  def handle_info({:new_feedback, feedback}, socket) do
    socket =
      socket
      |> put_flash(:info, "New feedback received: #{feedback.feedback_type}")
      |> assign(:feedback_list, Feedback.list_user_feedback())
      |> assign(:stats, Feedback.get_feedback_stats())

    {:noreply, socket}
  end

  def handle_info({:feedback_updated, _feedback}, socket) do
    socket =
      socket
      |> assign(:feedback_list, Feedback.list_user_feedback())
      |> assign(:stats, Feedback.get_feedback_stats())

    {:noreply, socket}
  end
end
