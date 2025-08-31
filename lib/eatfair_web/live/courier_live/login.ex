defmodule EatfairWeb.CourierLive.Login do
  use EatfairWeb, :live_view

  alias Eatfair.Accounts

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    # Redirect if already logged in as courier
    if socket.assigns.current_scope &&
         socket.assigns.current_scope.user &&
         socket.assigns.current_scope.user.role == "courier" do
      {:ok, redirect(socket, to: ~p"/courier/dashboard")}
    else
      form = to_form(%{"email" => "", "password" => ""}, as: "user")

      socket =
        socket
        |> assign(:page_title, "Courier Login")
        |> assign(:form, form)
        |> assign(:trigger_submit, false)

      {:ok, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("submit", %{"user" => user_params}, socket) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.get_user_by_email_and_password(email, password) do
      %{role: "courier"} = _user ->
        # Valid courier login - trigger traditional form submission to UserSessionController
        # which will handle session creation and redirect properly
        socket = assign(socket, :trigger_submit, true)
        {:noreply, socket}

      %{} = _user ->
        socket =
          socket
          |> put_flash(:error, "Access denied. Courier account required.")
          |> assign(:form, to_form(user_params, as: "user"))

        {:noreply, socket}

      nil ->
        socket =
          socket
          |> put_flash(:error, "Invalid email or password")
          |> assign(:form, to_form(user_params, as: "user"))

        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            🚚 Courier Login
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Sign in to your courier account
          </p>
        </div>

        <.form
          :let={f}
          for={@form}
          id="courier_login_form"
          action={~p"/users/log-in"}
          phx-submit="submit"
          phx-trigger-action={@trigger_submit}
          class="mt-8 space-y-6"
        >
          <div class="rounded-md shadow-sm -space-y-px">
            <div>
              <.input
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
              />
            </div>
            <div>
              <.input
                field={f[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
                required
              />
            </div>
          </div>

          <div>
            <.button
              type="submit"
              class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500"
            >
              Sign in
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
