defmodule EatfairWeb.OrderLive.Details do
  use EatfairWeb, :live_view
  import Bitwise

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
    changeset =
      Orders.change_order_details(%{
        email: "",
        delivery_address: socket.assigns.formatted_location || socket.assigns.location || "",
        phone_number: "",
        delivery_time: "as_soon_as_possible",
        special_instructions: ""
      })

    assign(socket, :order_form, to_form(changeset, as: :order))
  end

  defp calculate_delivery_time_options(socket) do
    restaurant = socket.assigns.restaurant

    # Get current time in restaurant's timezone
    restaurant_tz = restaurant.timezone || "Europe/Amsterdam"
    now = DateTime.now!(restaurant_tz)

    # Check if restaurant is open for orders
    if Eatfair.Restaurants.Restaurant.open_for_orders?(restaurant) do
      calculate_available_delivery_times(socket, restaurant, now, restaurant_tz)
    else
      # Restaurant is closed - show message and empty options
      socket
      |> assign(:delivery_time_options, [])
      |> assign(:minimum_delivery_time, nil)
      |> assign(:restaurant_closed_message, get_restaurant_closed_message(restaurant, now))
    end
  end

  defp calculate_available_delivery_times(socket, restaurant, now, restaurant_tz) do
    # Calculate minimum delivery time based on restaurant preparation time
    prep_time = restaurant.avg_preparation_time
    # Add buffer time
    min_time_minutes = prep_time + 15

    # Round up to nearest 15 minutes (ceiling)
    rounded_min = ceiling_to_15_minutes(min_time_minutes)

    # Calculate earliest delivery time from now
    min_delivery_time = DateTime.add(now, rounded_min * 60)

    # Get restaurant's last order time today
    last_order_time = Eatfair.Restaurants.Restaurant.last_order_time_today(restaurant)

    # Generate delivery time options
    options = [{"As soon as possible", "as_soon_as_possible"}]

    # Generate 15-minute interval options up to last delivery time or 12 hours, whichever is sooner
    max_time =
      if last_order_time do
        # Add delivery window after last order time
        # prep + 30min delivery
        DateTime.add(last_order_time, restaurant.avg_preparation_time * 60 + 30 * 60)
      else
        # 12 hours from now for more flexibility
        DateTime.add(now, 12 * 60 * 60)
      end

    time_options = generate_15_minute_intervals(min_delivery_time, max_time, restaurant_tz)

    all_options = options ++ time_options

    socket
    |> assign(:delivery_time_options, all_options)
    |> assign(:minimum_delivery_time, min_delivery_time)
    |> assign(:restaurant_closed_message, nil)
    |> assign(:delivery_timezone, restaurant_tz)
  end

  defp ceiling_to_15_minutes(minutes) when is_integer(minutes) do
    # Round up to nearest 15 minutes
    case rem(minutes, 15) do
      # Already multiple of 15
      0 -> minutes
      remainder -> minutes + (15 - remainder)
    end
  end

  defp generate_15_minute_intervals(start_time, end_time, timezone) do
    # Generate times in 15-minute intervals
    # 15 minutes in seconds
    interval_seconds = 15 * 60
    # Max 12 hours worth of options (48 * 15min)
    max_intervals = 48

    0..max_intervals
    |> Enum.map(fn i ->
      option_time = DateTime.add(start_time, i * interval_seconds)

      if DateTime.compare(option_time, end_time) == :lt do
        # Format time with timezone context
        formatted_time = Calendar.strftime(option_time, "%H:%M")
        timezone_abbr = get_timezone_abbreviation(timezone)

        # Calculate minutes from now for display
        minutes_from_now = DateTime.diff(option_time, DateTime.now!(timezone), :minute)

        display_text = "#{formatted_time} #{timezone_abbr} (#{minutes_from_now} min)"
        value = "#{minutes_from_now}"

        {display_text, value}
      else
        nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
  end

  defp get_timezone_abbreviation(timezone) do
    case timezone do
      "Europe/Amsterdam" ->
        "CET/CEST"

      "Europe/London" ->
        "GMT/BST"

      "America/New_York" ->
        "EST/EDT"

      "America/Los_Angeles" ->
        "PST/PDT"

      _ ->
        # Extract general abbreviation from timezone
        timezone
        |> String.split("/")
        |> List.last()
        |> String.slice(0..2)
        |> String.upcase()
    end
  end

  defp get_restaurant_closed_message(restaurant, current_time) do
    if restaurant.force_closed do
      reason = restaurant.force_closed_reason || "temporarily closed"
      "This restaurant is currently #{reason}. Please try again later."
    else
      # Calculate when restaurant will next be open
      next_open_time = calculate_next_open_time(restaurant, current_time)

      if next_open_time do
        formatted_time = Calendar.strftime(next_open_time, "%H:%M on %A")
        "This restaurant is currently closed. Orders will be available from #{formatted_time}."
      else
        "This restaurant is currently closed. Please check back later."
      end
    end
  end

  defp calculate_next_open_time(restaurant, current_time) do
    # Simple implementation - find next day restaurant is open
    # This could be enhanced to handle same-day reopening
    _current_day = Date.day_of_week(current_time)
    restaurant_tz = restaurant.timezone

    # Check next 7 days
    1..7
    |> Enum.find_value(fn days_ahead ->
      future_date = Date.add(DateTime.to_date(current_time), days_ahead)
      future_day = Date.day_of_week(future_date)

      day_bit = :math.pow(2, future_day - 1) |> round()
      operating_on_day? = (restaurant.operating_days &&& day_bit) > 0

      if operating_on_day? do
        # Calculate opening time for that day
        hours = div(restaurant.order_open_time, 60)
        minutes = rem(restaurant.order_open_time, 60)

        case Time.new(hours, minutes, 0) do
          {:ok, time} ->
            case DateTime.new(future_date, time, restaurant_tz) do
              {:ok, datetime} -> datetime
              _ -> nil
            end

          _ ->
            nil
        end
      else
        nil
      end
    end)
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

      confirmation_url =
        ~p"/order/#{restaurant_id}/confirm?cart=#{cart_encoded}&order_details=#{order_encoded}"

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
