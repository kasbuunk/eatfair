defmodule EatfairWeb.CourierLive.Dashboard do
  use EatfairWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Courier Dashboard")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900">
            🚚 Courier Dashboard
          </h1>
          <p class="mt-2 text-sm text-gray-600">
            Welcome, <%= @current_scope.user.name %>!
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
                      3
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
                      1
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
                      5
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Available Deliveries Section -->
        <div class="mt-8">
          <h2 class="text-lg font-medium text-gray-900 mb-4">Available Deliveries</h2>
          <div class="bg-white shadow overflow-hidden sm:rounded-md">
            <ul class="divide-y divide-gray-200">
              <!-- Sample delivery items -->
              <li class="px-4 py-4 hover:bg-gray-50">
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        Ready
                      </span>
                    </div>
                    <div class="ml-4">
                      <p class="text-sm font-medium text-gray-900">
                        Delivery #1234
                      </p>
                      <p class="text-sm text-gray-500">
                        Pizza Palace → 123 Main St
                      </p>
                    </div>
                  </div>
                  <div class="flex items-center space-x-2">
                    <span class="text-sm text-gray-500">$4.50</span>
                    <.button class="btn btn-primary btn-sm">
                      Accept
                    </.button>
                  </div>
                </div>
              </li>
              <!-- More delivery items would be here -->
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
