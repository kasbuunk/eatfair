defmodule EatfairWeb.OrderLive.Payment do
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
      |> assign(:order_details, %{})
      |> assign(:payment_method, "card")
      |> assign(:payment_processing, false)
      |> assign(:payment_error, nil)
      |> assign(:donation_amount, Decimal.new("0.00"))
      |> assign(:total_with_donation, Decimal.new("0.00"))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> apply_cart_data(params["cart"])
      |> apply_order_details(params["order_details"])
      |> calculate_initial_total()

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
        assign(socket, :order_details, order_details)

      {:error, _} ->
        socket
        |> put_flash(:error, "Invalid order details")
        |> push_navigate(to: ~p"/restaurants/#{socket.assigns.restaurant.id}")
    end
  end

  @impl true
  def handle_event("select_payment_method", %{"method" => method}, socket) do
    {:noreply, assign(socket, :payment_method, method)}
  end

  def handle_event("update_donation", %{"donation" => %{"amount" => amount_str}}, socket) do
    case parse_donation_amount(amount_str) do
      {:ok, donation_amount} ->
        total_with_donation = Decimal.add(socket.assigns.cart_total, donation_amount)

        socket =
          socket
          |> assign(:donation_amount, donation_amount)
          |> assign(:total_with_donation, total_with_donation)
          |> assign(:payment_error, nil)

        {:noreply, socket}

      {:error, reason} ->
        socket = assign(socket, :payment_error, reason)
        {:noreply, socket}
    end
  end

  def handle_event("process_payment", _params, socket) do
    # Set processing state
    socket = assign(socket, payment_processing: true, payment_error: nil)

    # Simulate payment processing
    Process.send_after(self(), :complete_payment, 2000)

    {:noreply, socket}
  end

  def handle_event("back_to_confirm", _params, socket) do
    # Navigate back to confirmation with all data preserved
    cart_encoded = encode_cart(socket.assigns.cart)
    restaurant_id = socket.assigns.restaurant.id
    order_encoded = encode_order_params(socket.assigns.order_details)

    confirm_url =
      ~p"/order/#{restaurant_id}/confirm?cart=#{cart_encoded}&order_details=#{order_encoded}"

    {:noreply, push_navigate(socket, to: confirm_url)}
  end

  @impl true
  def handle_info(:complete_payment, socket) do
    # Simulate payment processing result
    # 90% success rate for demo in development, 100% in test
    payment_success =
      if Mix.env() == :test do
        true
      else
        :rand.uniform() > 0.1
      end

    if payment_success do
      # Create order in database
      case create_order_from_cart(socket) do
        {:ok, order} ->
          # Process payment and update order status to confirmed
          payment_attrs = %{
            amount: socket.assigns.total_with_donation
          }

          case Orders.process_payment(order.id, payment_attrs) do
            {:ok, _payment} ->
              # Send email verification for anonymous orders
              if is_nil(socket.assigns[:current_scope]) do
                case Eatfair.Accounts.send_verification_email(order.customer_email, order: order) do
                  {:ok, _verification} ->
                    # Email sent successfully, continue normally
                    :ok

                  {:error, reason} ->
                    # Log error but don't block user flow
                    require Logger

                    Logger.error(
                      "Failed to send verification email for order #{order.id}: #{inspect(reason)}"
                    )
                end
              end

              # Navigate to success page
              success_url = ~p"/order/success/#{order.id}"

              socket =
                socket
                |> assign(:payment_processing, false)
                |> push_navigate(to: success_url)

              {:noreply, socket}

            {:error, reason} ->
              require Logger
              Logger.error("Payment processing failed for order #{order.id}: #{inspect(reason)}")

              socket =
                socket
                |> assign(:payment_processing, false)
                |> assign(:payment_error, "Payment processing failed. Please try again.")

              {:noreply, socket}
          end

        {:error, changeset} ->
          require Logger
          Logger.error("Order creation failed: #{inspect(changeset)}")

          socket =
            socket
            |> assign(:payment_processing, false)
            |> assign(:payment_error, "Failed to create order. Please try again.")

          {:noreply, socket}
      end
    else
      # Simulate payment failure
      socket =
        socket
        |> assign(:payment_processing, false)
        |> assign(
          :payment_error,
          "Payment failed. Please check your payment details and try again."
        )

      {:noreply, socket}
    end
  end

  # Helper functions
  defp create_order_from_cart(socket) do
    restaurant = socket.assigns.restaurant
    order_details = socket.assigns.order_details
    cart = socket.assigns.cart
    cart_total = socket.assigns.cart_total

    # Check if user is authenticated or if this is a guest order
    case socket.assigns[:current_scope] do
      %{user: %{id: user_id}} ->
        # Authenticated user - use regular order creation
        order_attrs = %{
          restaurant_id: restaurant.id,
          customer_id: user_id,
          customer_email: order_details["email"],
          customer_phone: order_details["phone_number"],
          delivery_address: order_details["delivery_address"],
          special_instructions: order_details["special_instructions"],
          total_price: cart_total,
          donation_amount: socket.assigns.donation_amount,
          donation_currency: "EUR",
          estimated_delivery_time: order_details["delivery_time"],
          status: "pending"
        }

        # Prepare order items
        items_attrs =
          Enum.map(cart, fn {meal_id, quantity} ->
            %{meal_id: meal_id, quantity: quantity}
          end)

        # Create order with items
        Orders.create_order_with_items(order_attrs, items_attrs)

      _ ->
        # Anonymous guest order - use anonymous order creation with automatic soft account
        order_attrs = %{
          restaurant_id: restaurant.id,
          customer_email: order_details["email"],
          customer_phone: order_details["phone_number"],
          delivery_address: order_details["delivery_address"],
          special_instructions: order_details["special_instructions"],
          total_price: cart_total,
          donation_amount: socket.assigns.donation_amount,
          donation_currency: "EUR",
          estimated_delivery_time: order_details["delivery_time"],
          status: "pending"
        }

        # Create anonymous order (this will create soft account + tracking token)
        case Orders.create_anonymous_order(order_attrs) do
          {:ok, order} ->
            # Add order items
            items_attrs =
              Enum.map(cart, fn {meal_id, quantity} ->
                %{meal_id: meal_id, quantity: quantity}
              end)

            case Orders.create_order_items(order.id, items_attrs) do
              {:ok, _items} ->
                # Reload order with associations
                order = Orders.get_order!(order.id)
                {:ok, order}

              error ->
                error
            end

          error ->
            error
        end
    end
  end

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
    "€#{Decimal.to_float(price) |> :erlang.float_to_binary(decimals: 2)}"
  end

  defp parse_donation_amount(""), do: {:ok, Decimal.new("0.00")}
  defp parse_donation_amount(nil), do: {:ok, Decimal.new("0.00")}

  defp parse_donation_amount(amount_str) when is_binary(amount_str) do
    case Decimal.parse(amount_str) do
      {amount, _} ->
        cond do
          Decimal.negative?(amount) ->
            {:error, "Donation amount cannot be negative"}

          Decimal.gt?(amount, 100) ->
            {:error, "Maximum donation amount is €100"}

          true ->
            {:ok, Decimal.new(amount_str)}
        end

      :error ->
        {:error, "Invalid donation amount"}
    end
  end

  defp parse_donation_amount(_), do: {:error, "Invalid donation amount"}

  defp calculate_initial_total(socket) do
    total_with_donation = Decimal.add(socket.assigns.cart_total, socket.assigns.donation_amount)
    assign(socket, :total_with_donation, total_with_donation)
  end
end
