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
      
    {:ok, socket}
  end

  @impl true 
  def handle_params(params, _url, socket) do
    socket = 
      socket
      |> apply_cart_data(params["cart"])
      |> apply_order_details(params["order_details"])
      
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
    
    confirm_url = ~p"/order/#{restaurant_id}/confirm?cart=#{cart_encoded}&order_details=#{order_encoded}"
    {:noreply, push_navigate(socket, to: confirm_url)}
  end

  @impl true
  def handle_info(:complete_payment, socket) do
    # Simulate payment processing result
    payment_success = :rand.uniform() > 0.1  # 90% success rate for demo

    if payment_success do
      # Create order in database
      case create_order_from_cart(socket) do
        {:ok, order} ->
          # Process payment and update order status to confirmed
          payment_attrs = %{
            amount: socket.assigns.cart_total
          }
          
          case Orders.process_payment(order.id, payment_attrs) do
            {:ok, _payment} ->
              # Navigate to success page
              success_url = ~p"/order/success/#{order.id}"
              socket = 
                socket
                |> assign(:payment_processing, false)
                |> push_navigate(to: success_url)
              
              {:noreply, socket}
            
            {:error, _reason} ->
              socket = 
                socket
                |> assign(:payment_processing, false)
                |> assign(:payment_error, "Payment processing failed. Please try again.")
              
              {:noreply, socket}
          end
        
        {:error, _changeset} ->
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
        |> assign(:payment_error, "Payment failed. Please check your payment details and try again.")
      
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
    {customer_id, customer_email, customer_phone} = 
      case socket.assigns[:current_scope] do
        %{user: %{id: user_id}} ->
          # Authenticated user - use their ID and store contact info for this order
          {user_id, order_details["email"], order_details["phone_number"]}
        
        _ ->
          # Guest order - create or get guest customer for SQLite constraint
          guest_customer_id = get_or_create_guest_customer_id()
          {guest_customer_id, order_details["email"], order_details["phone_number"]}
      end

    # Prepare order attributes
    order_attrs = %{
      restaurant_id: restaurant.id,
      customer_id: customer_id,
      customer_email: customer_email,
      customer_phone: customer_phone,
      delivery_address: order_details["delivery_address"],
      special_instructions: order_details["special_instructions"],
      total_price: cart_total,
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
  end

  # Get or create a dummy "guest" customer for guest orders
  # This is a workaround for SQLite's non-nullable constraint
  defp get_or_create_guest_customer_id do
    alias Eatfair.Accounts
    
    case Accounts.get_user_by_email("guest@eatfair.internal") do
      nil ->
        # Create guest user if it doesn't exist
        {:ok, guest_user} = Accounts.register_user(%{
          email: "guest@eatfair.internal",
          name: "Guest User",
          password: "dummy_password_123",
          phone_number: "+00-000-000-0000",
          role: "customer"
        })
        guest_user.id
      
      guest_user ->
        guest_user.id
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
    "$#{Decimal.to_float(price) |> :erlang.float_to_binary(decimals: 2)}"
  end
end
