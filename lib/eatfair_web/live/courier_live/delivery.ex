defmodule EatfairWeb.CourierLive.Delivery do
  use EatfairWeb, :live_view

  @impl Phoenix.LiveView
  def mount(%{"id" => delivery_id}, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Delivery ##{delivery_id}")
      |> assign(:delivery_id, delivery_id)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-gray-50">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div class="mb-8">
            <.link navigate={~p"/courier/dashboard"} class="text-sm text-blue-600 hover:text-blue-800">
              ← Back to Dashboard
            </.link>
            <h1 class="text-3xl font-bold text-gray-900 mt-2">
              🚚 Delivery #{@delivery_id}
            </h1>
          </div>

          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h2 class="text-lg font-medium text-gray-900 mb-4">Delivery Details</h2>
              <p class="text-gray-600">Delivery management interface would be implemented here.</p>
              <p class="text-gray-600 mt-2">Features would include:</p>
              <ul class="list-disc list-inside text-gray-600 mt-2 space-y-1">
                <li>Order details and customer information</li>
                <li>GPS navigation and route optimization</li>
                <li>Real-time location tracking</li>
                <li>Delivery status updates</li>
                <li>Customer communication</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
