defmodule EatfairWeb.RestaurantLive.Discovery do
  use EatfairWeb, :live_view

  alias Eatfair.Restaurants

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Discover Restaurants")
     |> assign(:restaurants, [])
     |> assign(:filters, %{})
     |> assign(:search_query, "")
     |> assign(:location, nil)
     |> load_restaurants()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_filters(socket, params)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> search_restaurants(query)}
  end

  @impl true
  def handle_event("filter_cuisine", %{"cuisine" => cuisine}, socket) do
    filters = Map.put(socket.assigns.filters, :cuisine, cuisine)
    {:noreply, apply_filters(socket, filters)}
  end

  @impl true
  def handle_event("filter_price", %{"max_price" => max_price}, socket) do
    filters = Map.put(socket.assigns.filters, :max_price, max_price)
    {:noreply, apply_filters(socket, filters)}
  end

  @impl true
  def handle_event("filter_delivery_time", %{"max_delivery_time" => max_time}, socket) do
    filters = Map.put(socket.assigns.filters, :max_delivery_time, max_time)
    {:noreply, apply_filters(socket, filters)}
  end

  @impl true
  def handle_event("search_location", %{"location" => %{"address" => address}}, socket) do
    # Geocode the address and filter restaurants within delivery range
    case Eatfair.GeoUtils.geocode_address(address) do
      {:ok, %{latitude: lat, longitude: lon}} ->
        # Filter restaurants that can deliver to this location
        filtered_restaurants =
          Restaurants.list_open_restaurants()
          |> Enum.filter(fn restaurant ->
            Eatfair.GeoUtils.within_delivery_range?(
              restaurant.latitude,
              restaurant.longitude,
              Decimal.new(Float.to_string(lat)),
              Decimal.new(Float.to_string(lon)),
              restaurant.delivery_radius_km
            )
          end)

        {:noreply,
         socket
         |> assign(:location, address)
         |> assign(:restaurants, filtered_restaurants)
         |> put_flash(
           :info,
           "Found #{length(filtered_restaurants)} restaurants delivering to #{address}"
         )}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not find location: #{address}")}
    end
  end

  @impl true
  def handle_event("view_restaurant", %{"id" => restaurant_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/restaurants/#{restaurant_id}")}
  end

  defp load_restaurants(socket) do
    restaurants =
      case get_current_user_id(socket) do
        nil -> Restaurants.list_restaurants_with_location_data()
        user_id -> Restaurants.list_restaurants_for_user(user_id)
      end

    assign(socket, :restaurants, restaurants)
  end

  defp search_restaurants(socket, query) when query == "" do
    load_restaurants(socket)
  end

  defp search_restaurants(socket, query) do
    restaurants =
      case get_current_user_id(socket) do
        nil -> Restaurants.search_restaurants(query)
        user_id -> Restaurants.search_restaurants_with_location(query, user_id)
      end

    assign(socket, :restaurants, restaurants)
  end

  defp apply_filters(socket, filters) when is_map(filters) do
    restaurants =
      case get_current_user_id(socket) do
        nil -> Restaurants.filter_restaurants(filters)
        user_id -> Restaurants.filter_restaurants_with_location(filters, user_id)
      end

    socket
    |> assign(:filters, filters)
    |> assign(:restaurants, restaurants)
  end

  defp apply_filters(socket, params) when is_map(params) do
    filters = build_filters_from_params(params)
    apply_filters(socket, filters)
  end

  defp get_current_user_id(socket) do
    case socket.assigns.current_scope do
      %{user: %{id: user_id}} -> user_id
      _ -> nil
    end
  end

  defp build_filters_from_params(params) do
    params
    |> Enum.reduce(%{}, fn
      {"cuisine", value}, acc when value != "" ->
        Map.put(acc, :cuisine, value)

      {"max_price", value}, acc when value != "" ->
        Map.put(acc, :max_price, value)

      {"max_delivery_time", value}, acc when value != "" ->
        Map.put(acc, :max_delivery_time, value)

      _other, acc ->
        acc
    end)
  end
end
