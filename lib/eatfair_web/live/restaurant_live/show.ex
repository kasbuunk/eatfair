defmodule EatfairWeb.RestaurantLive.Show do
  use EatfairWeb, :live_view

  alias Eatfair.Restaurants

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    restaurant = Restaurants.get_restaurant!(id)
    
    socket = 
      socket
      |> assign(:restaurant, restaurant)
      |> assign(:cart, %{})
      |> assign(:cart_total, Decimal.new(0))
    
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, socket.assigns.restaurant.name)
  end

  @impl true
  def handle_event("add_to_cart", %{"meal_id" => meal_id}, socket) do
    meal_id = String.to_integer(meal_id)
    meal = find_meal(socket.assigns.restaurant, meal_id)
    
    if meal do
      cart = socket.assigns.cart
      current_quantity = Map.get(cart, meal_id, 0)
      updated_cart = Map.put(cart, meal_id, current_quantity + 1)
      
      cart_total = calculate_cart_total(updated_cart, socket.assigns.restaurant)
      
      socket = 
        socket
        |> assign(:cart, updated_cart)
        |> assign(:cart_total, cart_total)
        |> put_flash(:info, "Added #{meal.name} to cart")
      
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "Meal not found")}
    end
  end

  def handle_event("remove_from_cart", %{"meal_id" => meal_id}, socket) do
    meal_id = String.to_integer(meal_id)
    cart = socket.assigns.cart
    
    updated_cart = 
      case Map.get(cart, meal_id, 0) do
        quantity when quantity > 1 -> Map.put(cart, meal_id, quantity - 1)
        _ -> Map.delete(cart, meal_id)
      end
    
    cart_total = calculate_cart_total(updated_cart, socket.assigns.restaurant)
    
    socket = 
      socket
      |> assign(:cart, updated_cart)
      |> assign(:cart_total, cart_total)
    
    {:noreply, socket}
  end

  def handle_event("checkout", _params, socket) do
    case socket.assigns.current_scope do
      %{user: nil} ->
        # Redirect to login with return URL
        {:noreply, push_navigate(socket, to: ~p"/users/log-in")}
      
      %{user: _user} ->
        # Navigate to checkout with cart data
        cart_encoded = encode_cart(socket.assigns.cart)
        restaurant_id = socket.assigns.restaurant.id
        
        checkout_url = ~p"/checkout?restaurant_id=#{restaurant_id}&cart=#{cart_encoded}"
        {:noreply, push_navigate(socket, to: checkout_url)}
    end
  end

  defp find_meal(restaurant, meal_id) do
    restaurant.menus
    |> Enum.flat_map(& &1.meals)
    |> Enum.find(&(&1.id == meal_id))
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

  defp cart_item_count(cart) do
    cart |> Map.values() |> Enum.sum()
  end

  defp encode_cart(cart) do
    cart
    |> Jason.encode!()
    |> URI.encode()
  end

  defp format_price(price) do
    "$#{Decimal.to_float(price) |> :erlang.float_to_binary(decimals: 2)}"
  end

  defp format_delivery_time(minutes) do
    "#{minutes} min"
  end

  defp format_rating(rating) when is_nil(rating), do: "No rating"
  defp format_rating(rating) do
    "#{Decimal.to_float(rating)}/5"
  end
end
