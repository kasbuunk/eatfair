defmodule EatfairWeb.OrderLive.Confirm do
  use EatfairWeb, :live_view

  alias Eatfair.Restaurants

  @impl true
  def mount(%{"restaurant_id" => restaurant_id}, _session, socket) do
    restaurant = Restaurants.get_restaurant!(restaurant_id)

    socket =
      socket
      |> assign(:restaurant, restaurant)
      |> assign(:cart, %{})
      |> assign(:cart_total, Decimal.new(0))
      |> assign(:order_details, %{})
      |> assign(:delivery_time_display, "")
      |> assign(:estimated_delivery_time, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> apply_cart_data(params["cart"])
      |> apply_order_details(params["order_details"])
      |> calculate_estimated_delivery()

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

  defp apply_order_details(socket, nil), do: socket

  defp apply_order_details(socket, order_details_param) when is_binary(order_details_param) do
    case decode_order_details(order_details_param) do
      {:ok, order_details} ->
        delivery_display =
          format_delivery_time_display(order_details["delivery_time"], socket.assigns.restaurant)

        socket
        |> assign(:order_details, order_details)
        |> assign(:delivery_time_display, delivery_display)

      {:error, _} ->
        socket
        |> put_flash(:error, "Invalid order details")
        |> push_navigate(to: ~p"/restaurants/#{socket.assigns.restaurant.id}")
    end
  end

  defp calculate_estimated_delivery(socket) do
    delivery_time = socket.assigns.order_details["delivery_time"]

    estimated_time =
      case delivery_time do
        "as_soon_as_possible" ->
          prep_time = socket.assigns.restaurant.avg_preparation_time
          # Add buffer time
          min_time_minutes = prep_time + 15
          rounded_min = (div(min_time_minutes - 1, 15) + 1) * 15
          DateTime.add(DateTime.utc_now(), rounded_min * 60)

        time_str when is_binary(time_str) ->
          case Integer.parse(time_str) do
            {minutes, ""} -> DateTime.add(DateTime.utc_now(), minutes * 60)
            _ -> nil
          end

        _ ->
          nil
      end

    assign(socket, :estimated_delivery_time, estimated_time)
  end

  @impl true
  def handle_event("confirm_order", _params, socket) do
    # Navigate to payment stage
    cart_encoded = encode_cart(socket.assigns.cart)
    restaurant_id = socket.assigns.restaurant.id
    order_encoded = encode_order_params(socket.assigns.order_details)

    payment_url =
      ~p"/order/#{restaurant_id}/payment?cart=#{cart_encoded}&order_details=#{order_encoded}"

    {:noreply, push_navigate(socket, to: payment_url)}
  end

  def handle_event("back_to_details", _params, socket) do
    # Navigate back to order details with all data preserved
    cart_encoded = encode_cart(socket.assigns.cart)
    restaurant_id = socket.assigns.restaurant.id
    location = socket.assigns.order_details["delivery_address"] || ""

    details_url = ~p"/order/#{restaurant_id}/details?cart=#{cart_encoded}&location=#{location}"
    {:noreply, push_navigate(socket, to: details_url)}
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

  defp decode_order_details(order_details_param) do
    try do
      order_details_param
      |> URI.decode()
      |> Jason.decode!()
      |> then(&{:ok, &1})
    rescue
      _ -> {:error, :invalid_order_details}
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

  defp format_delivery_time_display(delivery_time, restaurant) do
    case delivery_time do
      "as_soon_as_possible" ->
        "As soon as possible (~#{restaurant.avg_preparation_time + 15} minutes)"

      time_str when is_binary(time_str) ->
        case Integer.parse(time_str) do
          {minutes, ""} -> "In approximately #{minutes} minutes"
          _ -> "As soon as possible"
        end

      _ ->
        "As soon as possible"
    end
  end
end
