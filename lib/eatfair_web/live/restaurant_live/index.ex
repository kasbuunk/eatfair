defmodule EatfairWeb.RestaurantLive.Index do
  use EatfairWeb, :live_view

  alias Eatfair.Restaurants

  @impl true
  def mount(_params, _session, socket) do
    cuisines = Restaurants.list_cuisines()
    restaurants = Restaurants.list_open_restaurants()
    
    socket = 
      socket
      |> assign(:cuisines, cuisines)
      |> assign(:selected_cuisine, nil)
      |> stream(:restaurants, restaurants)
    
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Browse Restaurants")
  end

  @impl true
  def handle_event("filter_by_cuisine", %{"cuisine_id" => cuisine_id}, socket) do
    selected_cuisine = if cuisine_id == "", do: nil, else: String.to_integer(cuisine_id)
    
    restaurants = 
      case selected_cuisine do
        nil -> Restaurants.list_open_restaurants()
        id -> 
          Restaurants.list_open_restaurants()
          |> Enum.filter(fn restaurant -> 
            Enum.any?(restaurant.cuisines, &(&1.id == id))
          end)
      end
    
    socket = 
      socket
      |> assign(:selected_cuisine, selected_cuisine)
      |> stream(:restaurants, restaurants, reset: true)
    
    {:noreply, socket}
  end

  defp format_delivery_time(minutes) do
    "#{minutes}"
  end

  defp format_rating(rating) when is_nil(rating), do: "No rating"
  defp format_rating(rating) do
    "#{Decimal.to_float(rating)}/5"
  end

  defp format_min_order_value(min_order) when is_nil(min_order), do: ""
  defp format_min_order_value(min_order) do
    "#{Decimal.to_float(min_order)}"
  end
end
