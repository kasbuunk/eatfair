defmodule EatfairWeb.RestaurantLive.Dashboard do
  @moduledoc """
  Restaurant dashboard for daily operations management.

  Empowers restaurant owners with simple, powerful tools to manage their business.
  Implements the project specification: "Restaurant owners retain 100% of their revenue
  while maintaining control over their customer relationships"
  """

  use EatfairWeb, :live_view

  alias Eatfair.Restaurants

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    case Restaurants.get_user_restaurant(user.id) do
      nil ->
        # No restaurant - guide to onboarding
        {:ok, redirect(socket, to: ~p"/restaurant/onboard")}

      restaurant ->
        # Restaurant owner - show dashboard
        socket =
          socket
          |> assign(:restaurant, restaurant)
          |> assign(:page_title, "#{restaurant.name} - Dashboard")

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("toggle_status", _params, socket) do
    restaurant = socket.assigns.restaurant
    new_status = !restaurant.is_open

    case Restaurants.update_restaurant(restaurant, %{is_open: new_status}) do
      {:ok, updated_restaurant} ->
        status_message = if new_status, do: "Restaurant opened!", else: "Restaurant closed"

        socket =
          socket
          |> assign(:restaurant, updated_restaurant)
          |> put_flash(:info, status_message)

        {:noreply, socket}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Unable to update restaurant status")
        {:noreply, socket}
    end
  end
end
