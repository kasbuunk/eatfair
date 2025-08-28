defmodule EatfairWeb.OrderLive.Details do
  use EatfairWeb, :live_view

  alias Eatfair.Restaurants
  alias Eatfair.Orders

  @impl true
  def mount(%{"restaurant_id" => restaurant_id}, _session, socket) do
    restaurant = Restaurants.get_restaurant!(restaurant_id)
    
    socket = 
      socket
      |> assign(:restaurant, restaurant)
      |> assign(:cart, %{})
      |> assign(:cart_total, Decimal.new(0))
      |> assign(:location, "")
      |> assign(:formatted_location, "")
      |> assign(:order_form, nil)
      |> assign(:delivery_time_options, [])
      |> assign(:minimum_delivery_time, nil)
      
    {:ok, socket}
  end

  @impl true 
  def handle_params(params, _url, socket) do
    socket = 
      socket
      |> apply_cart_data(params["cart"])
      |> apply_location_data(params["location"])
      |> initialize_order_form()
      |> calculate_delivery_time_options()
      
    {:noreply, socket}
  end

  defp apply_cart_data(socket, nil), do: socket
  defp apply_cart_data(socket, cart_param) when is_binary(cart_param) do
    case decode_cart(cart_param) do
      {:ok, cart} ->
        cart_total = calculate_cart_total(cart, socket.assigns.restaurant)
        socket
        |> assign(:cart, cart)
        |> assign(:cart_total, cart_total)
      
      {:error, _} ->
        socket
        |> put_flash(:error, "Invalid cart data")
        |> push_navigate(to: ~p"/restaurants/#{socket.assigns.restaurant.id}")
    end
  end

  defp apply_location_data(socket, nil), do: socket
  defp apply_location_data(socket, location) when is_binary(location) do
    # Use location service to get formatted address
    case Eatfair.LocationServices.geocode_address(location) do
      {:ok, %{formatted_address: formatted_address}} ->
        socket
        |> assign(:location, location)
        |> assign(:formatted_location, formatted_address || location)
      
      {:error, _} ->
        socket
        |> assign(:location, location) 
        |> assign(:formatted_location, location)
    end
  end

  defp initialize_order_form(socket) do
    changeset = Orders.change_order_details(%{
      email: "",
      delivery_address: socket.assigns.formatted_location || socket.assigns.location || "",
      phone_number: "",
      delivery_time: "as_soon_as_possible",
      special_instructions: ""
    })
    
    assign(socket, :order_form, to_form(changeset, as: :order))
  end

  defp calculate_delivery_time_options(socket) do
    # Calculate minimum delivery time based on restaurant preparation time
    prep_time = socket.assigns.restaurant.avg_preparation_time
    min_time_minutes = prep_time + 15 # Add buffer time
    
    # Round up to nearest 15 minutes
    rounded_min = (div(min_time_minutes - 1, 15) + 1) * 15
    
    now = DateTime.utc_now()
    min_delivery_time = DateTime.add(now, rounded_min * 60)
    
    # Generate options for next 4 hours in 15-minute intervals
    options = [{"As soon as possible", "as_soon_as_possible"}]
    
    time_options = 0..15
    |> Enum.map(fn i ->
      time = DateTime.add(min_delivery_time, i * 15 * 60)
      formatted_time = Calendar.strftime(time, "%H:%M")
      {"#{formatted_time} (#{rounded_min + (i * 15)} min)", "#{rounded_min + (i * 15)}"}
    end)
    
    all_options = options ++ time_options
    
    socket
    |> assign(:delivery_time_options, all_options)
    |> assign(:minimum_delivery_time, min_delivery_time)
  end

  @impl true
  def handle_event("validate_order", %{"order" => order_params}, socket) do
    changeset = Orders.change_order_details(order_params)
    {:noreply, assign(socket, :order_form, to_form(changeset, as: :order))}
  end

  def handle_event("submit_order", %{"order" => order_params}, socket) do
    changeset = Orders.change_order_details(order_params)
    
    if changeset.valid? do
      # Navigate to confirmation stage with all data
      cart_encoded = encode_cart(socket.assigns.cart)
      restaurant_id = socket.assigns.restaurant.id
      order_encoded = encode_order_params(order_params)
      
      confirmation_url = ~p"/order/#{restaurant_id}/confirm?cart=#{cart_encoded}&order_details=#{order_encoded}"
      {:noreply, push_navigate(socket, to: confirmation_url)}
    else
      {:noreply, assign(socket, :order_form, to_form(changeset, as: :order))}
    end
  end

  def handle_event("back_to_restaurant", _params, socket) do
    restaurant_id = socket.assigns.restaurant.id
    _cart_encoded = encode_cart(socket.assigns.cart)
    location = socket.assigns.location
    
    back_url = ~p"/restaurants/#{restaurant_id}?location=#{location}"
    {:noreply, push_navigate(socket, to: back_url)}
  end

  # Helper functions
  defp decode_cart(cart_param) do
    try do
      cart_param
      |> URI.decode()
      |> Jason.decode!()
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Map.new()
      |> then(&{:ok, &1})
    rescue
      _ -> {:error, :invalid_cart}
    end
  end

  defp encode_cart(cart) do
    cart
    |> Jason.encode!()
    |> URI.encode()
  end

  defp encode_order_params(order_params) do
    order_params
    |> Jason.encode!()
    |> URI.encode()
  end

  defp calculate_cart_total(cart, restaurant) do
    Enum.reduce(cart, Decimal.new(0), fn {meal_id, quantity}, acc ->
      meal = find_meal(restaurant, meal_id)

      if meal do
        item_total = Decimal.mult(meal.price, quantity)
        Decimal.add(acc, item_total)
      else
        acc
      end
    end)
  end

  defp find_meal(restaurant, meal_id) do
    restaurant.menus
    |> Enum.flat_map(& &1.meals)
    |> Enum.find(&(&1.id == meal_id))
  end

  defp format_price(price) do
    "$#{Decimal.to_float(price) |> :erlang.float_to_binary(decimals: 2)}"
  end
end
