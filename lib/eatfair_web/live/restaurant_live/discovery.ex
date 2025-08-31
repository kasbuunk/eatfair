defmodule EatfairWeb.RestaurantLive.Discovery do
  use EatfairWeb, :live_view

  alias Eatfair.Restaurants
  alias Eatfair.Restaurants.Restaurant
  alias Eatfair.Accounts
  alias Eatfair.LocationInference

  @impl true
  def mount(_params, _session, socket) do
    user_has_address = user_has_address?(socket)
    cuisines = Restaurants.list_cuisines()

    # Default filter state - empty cuisines list means "All" is selected
    default_filters = %{
      delivery_available: true,
      currently_open: true,
      # Empty list means "All cuisines" is selected
      cuisines: []
    }

    {:ok,
     socket
     |> assign(:page_title, "Discover Restaurants")
     |> assign(:restaurants, [])
     |> assign(:filters, default_filters)
     |> assign(:search_query, "")
     |> assign(:location, nil)
     |> assign(:user_has_address, user_has_address)
     |> assign(:cuisines, cuisines)
     |> assign(:cuisine_counts, %{})
     |> assign(:cuisines_with_counts, [])
     |> assign(:show_cuisine_dropdown, false)
     |> load_restaurants()
     |> calculate_cuisine_counts()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      case params["location"] do
        nil ->
          socket

        location ->
          # Store location from homepage navigation
          socket
          |> LocationInference.store_session_location(location)
          |> assign(:location, location)
          |> apply_location_filter(location)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> search_restaurants(query)}
  end

  @impl true
  def handle_event("toggle_delivery_filter", _params, socket) do
    current_value = socket.assigns.filters.delivery_available
    filters = Map.put(socket.assigns.filters, :delivery_available, !current_value)
    {:noreply, apply_filters_with_counts(socket, filters)}
  end

  @impl true
  def handle_event("toggle_open_filter", _params, socket) do
    current_value = socket.assigns.filters.currently_open
    filters = Map.put(socket.assigns.filters, :currently_open, !current_value)
    {:noreply, apply_filters_with_counts(socket, filters)}
  end

  @impl true
  def handle_event("toggle_cuisine", %{"cuisine_id" => cuisine_id_str}, socket) do
    cuisine_id = String.to_integer(cuisine_id_str)
    current_cuisines = socket.assigns.filters.cuisines

    updated_cuisines =
      if cuisine_id in current_cuisines do
        List.delete(current_cuisines, cuisine_id)
      else
        [cuisine_id | current_cuisines]
      end

    filters = Map.put(socket.assigns.filters, :cuisines, updated_cuisines)
    {:noreply, apply_filters_with_counts(socket, filters)}
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

      {:error, :invalid_input} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid address format: #{address}")}
    end
  end

  @impl true
  def handle_event("view_restaurant", %{"id" => restaurant_id}, socket) do
    url =
      case socket.assigns.location do
        nil -> ~p"/restaurants/#{restaurant_id}"
        location -> ~p"/restaurants/#{restaurant_id}?location=#{location}"
      end

    {:noreply, push_navigate(socket, to: url)}
  end

  @impl true
  def handle_event("toggle_cuisine_dropdown", _params, socket) do
    {:noreply, assign(socket, :show_cuisine_dropdown, !socket.assigns.show_cuisine_dropdown)}
  end

  @impl true
  def handle_event("select_all_cuisines", _params, socket) do
    # When "All" is selected, unselect all individual cuisines (empty list)
    filters = Map.put(socket.assigns.filters, :cuisines, [])

    {:noreply,
     socket
     |> assign(:show_cuisine_dropdown, false)
     |> apply_filters_with_counts(filters)}
  end

  @impl true
  def handle_info({"location_autocomplete_selected", selected_address}, socket) do
    # Apply the selected address as a location filter
    socket = assign(socket, :location, selected_address)

    # Apply location filter to restaurants
    socket = apply_location_filter(socket, selected_address)

    {:noreply,
     socket
     |> put_flash(:info, "Showing restaurants near #{selected_address}")}
  end

  @impl true
  def handle_info({:hide_suggestions, _component_id}, socket) do
    # Handle hide suggestions message from AddressAutocomplete component
    {:noreply, socket}
  end

  @impl true
  def handle_info({"input_change", _value}, socket) do
    # Handle input change message from AddressAutocomplete component
    {:noreply, socket}
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
    # When search is cleared, reapply current filters to get proper restaurant list
    apply_filters_with_counts(socket, socket.assigns.filters)
  end

  defp search_restaurants(socket, query) do
    # Get all restaurants as starting point
    all_restaurants =
      case get_current_user_id(socket) do
        nil -> Restaurants.list_restaurants_with_location_data()
        user_id -> Restaurants.list_restaurants_for_user(user_id)
      end

    # Apply location filter first if location is set
    base_restaurants =
      case socket.assigns.location do
        nil ->
          all_restaurants

        address ->
          case Eatfair.GeoUtils.geocode_address(address) do
            {:ok, %{latitude: lat, longitude: lon}} ->
              filter_by_location(all_restaurants, lat, lon)

            {:error, :not_found} ->
              all_restaurants

            {:error, :invalid_input} ->
              all_restaurants
          end
      end

    # Apply search filter to name-based filtering
    search_filtered_restaurants = filter_by_search_query(base_restaurants, query)

    # Apply all current filters on top of search results
    final_restaurants = filter_by_current_filters(search_filtered_restaurants, socket.assigns.filters)

    socket
    |> assign(:restaurants, final_restaurants)
    |> calculate_cuisine_counts()
  end

  defp get_current_user_id(socket) do
    case socket.assigns.current_scope do
      %{user: %{id: user_id}} -> user_id
      _ -> nil
    end
  end

  defp user_has_address?(socket) do
    case socket.assigns.current_scope do
      %{user: user} ->
        addresses = Accounts.list_user_addresses(user.id)
        length(addresses) > 0

      _ ->
        false
    end
  end

  defp apply_location_filter(socket, address) do
    # Apply location filter when coming from homepage
    case Eatfair.GeoUtils.geocode_address(address) do
      {:ok, %{latitude: lat, longitude: lon}} ->
        filtered_restaurants =
          socket.assigns.restaurants
          |> filter_by_location(lat, lon)
          |> filter_by_current_filters(socket.assigns.filters)
          |> sort_by_distance(lat, lon)

        socket =
          socket
          |> assign(:restaurants, filtered_restaurants)
          |> calculate_cuisine_counts()

        # Check if any restaurants were found after filtering
        case length(filtered_restaurants) do
          0 ->
            socket
            |> put_flash(
              :info,
              "No restaurants found that deliver to #{address}. Showing all restaurants."
            )
            # Keep the location for user reference but show all restaurants
            |> load_restaurants()
            |> calculate_cuisine_counts()

          count ->
            socket
            |> put_flash(:info, "Found #{count} restaurants delivering to #{address}")
        end

      {:error, :not_found} ->
        socket
        |> put_flash(:error, "Could not find location: #{address}")

      {:error, :invalid_input} ->
        socket
        |> put_flash(:error, "Invalid address format: #{address}")
    end
  end

  defp apply_filters_with_counts(socket, filters) do
    all_restaurants =
      case get_current_user_id(socket) do
        nil -> Restaurants.list_restaurants_with_location_data()
        user_id -> Restaurants.list_restaurants_for_user(user_id)
      end

    # Apply location filter first if location is set
    base_restaurants =
      case socket.assigns.location do
        nil ->
          all_restaurants

        address ->
          case Eatfair.GeoUtils.geocode_address(address) do
            {:ok, %{latitude: lat, longitude: lon}} ->
              filter_by_location(all_restaurants, lat, lon)

            {:error, :not_found} ->
              all_restaurants

            {:error, :invalid_input} ->
              all_restaurants
          end
      end

    # Apply current filters
    filtered_restaurants = filter_by_current_filters(base_restaurants, filters)

    socket
    |> assign(:filters, filters)
    |> assign(:restaurants, filtered_restaurants)
    |> calculate_cuisine_counts()
  end

  defp filter_by_location(restaurants, lat, lon) do
    restaurants
    |> Enum.filter(fn restaurant ->
      Eatfair.GeoUtils.within_delivery_range?(
        restaurant.latitude,
        restaurant.longitude,
        Decimal.new(Float.to_string(lat)),
        Decimal.new(Float.to_string(lon)),
        restaurant.delivery_radius_km
      )
    end)
  end

  defp filter_by_current_filters(restaurants, filters) do
    restaurants
    |> filter_by_delivery_available(filters.delivery_available)
    |> filter_by_currently_open(filters.currently_open)
    |> filter_by_selected_cuisines(filters.cuisines)
  end

  defp filter_by_delivery_available(restaurants, true), do: restaurants

  defp filter_by_delivery_available(restaurants, false) do
    # When delivery filter is OFF, show all restaurants (pickup + delivery)
    restaurants
  end

  defp filter_by_currently_open(restaurants, true) do
    restaurants |> Enum.filter(&Restaurant.open_for_orders?/1)
  end

  defp filter_by_currently_open(restaurants, false), do: restaurants

  # Empty list means "All" cuisines
  defp filter_by_selected_cuisines(restaurants, []), do: restaurants

  defp filter_by_selected_cuisines(restaurants, selected_cuisine_ids)
       when is_list(selected_cuisine_ids) do
    restaurants
    |> Enum.filter(fn restaurant ->
      restaurant.cuisines
      |> Enum.any?(fn cuisine -> cuisine.id in selected_cuisine_ids end)
    end)
  end

  defp sort_by_distance(restaurants, lat, lon) do
    restaurants
    |> Enum.map(fn restaurant ->
      distance =
        Eatfair.GeoUtils.haversine_distance(
          Decimal.to_float(restaurant.latitude),
          Decimal.to_float(restaurant.longitude),
          lat,
          lon
        )

      {restaurant, distance}
    end)
    |> Enum.sort_by(fn {_, distance} -> distance end)
    |> Enum.map(fn {restaurant, _} -> restaurant end)
  end

  defp filter_by_search_query(restaurants, query) do
    search_query = String.downcase(query)

    restaurants
    |> Enum.filter(fn restaurant ->
      String.contains?(String.downcase(restaurant.name), search_query)
    end)
  end

  defp calculate_cuisine_counts(socket) do
    # Calculate how many restaurants are available for each cuisine
    # based on current location and other filters (excluding cuisine filter)
    base_restaurants =
      case socket.assigns.location do
        nil ->
          case get_current_user_id(socket) do
            nil -> Restaurants.list_restaurants_with_location_data()
            user_id -> Restaurants.list_restaurants_for_user(user_id)
          end

        address ->
          case Eatfair.GeoUtils.geocode_address(address) do
            {:ok, %{latitude: lat, longitude: lon}} ->
              case get_current_user_id(socket) do
                nil -> Restaurants.list_restaurants_with_location_data()
                user_id -> Restaurants.list_restaurants_for_user(user_id)
              end
              |> filter_by_location(lat, lon)

            {:error, :not_found} ->
              case get_current_user_id(socket) do
                nil -> Restaurants.list_restaurants_with_location_data()
                user_id -> Restaurants.list_restaurants_for_user(user_id)
              end

            {:error, :invalid_input} ->
              case get_current_user_id(socket) do
                nil -> Restaurants.list_restaurants_with_location_data()
                user_id -> Restaurants.list_restaurants_for_user(user_id)
              end
          end
      end

    filters_without_cuisine = %{
      delivery_available: socket.assigns.filters.delivery_available,
      currently_open: socket.assigns.filters.currently_open,
      # All cuisines
      cuisines: Enum.map(socket.assigns.cuisines, & &1.id)
    }

    available_restaurants = filter_by_current_filters(base_restaurants, filters_without_cuisine)

    cuisine_counts =
      socket.assigns.cuisines
      |> Map.new(fn cuisine ->
        count =
          available_restaurants
          |> Enum.count(fn restaurant ->
            Enum.any?(restaurant.cuisines, &(&1.id == cuisine.id))
          end)

        {cuisine.id, count}
      end)

    cuisines_with_counts =
      socket.assigns.cuisines
      |> Enum.map(fn cuisine -> {cuisine, Map.get(cuisine_counts, cuisine.id, 0)} end)

    socket
    |> assign(:cuisine_counts, cuisine_counts)
    |> assign(:cuisines_with_counts, cuisines_with_counts)
  end
end
