defmodule EatfairWeb.CheckoutLive do
  use EatfairWeb, :live_view

  alias Eatfair.{Cart, Orders, Restaurants}

  @impl true
  def mount(params, _session, socket) do
    case socket.assigns.current_scope do
      %{user: nil} ->
        {:ok, push_navigate(socket, to: ~p"/users/log-in")}
      
      %{user: user} ->
        # Get cart data from URL parameters or redirect if no cart
        case params do
          %{"restaurant_id" => restaurant_id, "cart" => cart_param} ->
            restaurant = Restaurants.get_restaurant!(restaurant_id)
            cart = decode_cart(cart_param)
            cart_items = Cart.create_cart_items(cart, restaurant)
            cart_total = Cart.calculate_total(cart_items)
            
            # Validate minimum order
            case Cart.validate_minimum_order(cart_total, restaurant) do
              {:ok, _} ->
                form = to_form(%{
                  "delivery_address" => user.default_address || "",
                  "delivery_notes" => "",
                  "phone_number" => user.phone_number || ""
                })
                
                socket = 
                  socket
                  |> assign(:restaurant, restaurant)
                  |> assign(:cart_items, cart_items)
                  |> assign(:cart_total, cart_total)
                  |> assign(:form, form)
                  |> assign(:step, :review)
                  |> assign(:processing, false)
                
                {:ok, socket}
              
              {:error, :minimum_not_met, min_value} ->
                socket = 
                  socket
                  |> put_flash(:error, "Minimum order of #{format_price(min_value)} not met")
                  |> push_navigate(to: ~p"/restaurants/#{restaurant_id}")
                
                {:ok, socket}
            end
          
          _ ->
            {:ok, push_navigate(socket, to: ~p"/")}
        end
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Checkout")
  end

  @impl true
  def handle_event("validate", params, socket) do
    # Extract the form data from params
    order_params = Map.take(params, ["delivery_address", "delivery_notes", "phone_number"])
    form = to_form(order_params)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("place_order", params, socket) do
    if socket.assigns.processing do
      {:noreply, socket}
    else
      socket = assign(socket, :processing, true)
      
      user = socket.assigns.current_scope.user
      cart_items = socket.assigns.cart_items
      restaurant = socket.assigns.restaurant
      cart_total = socket.assigns.cart_total
      
      # Extract order params
      order_params = Map.take(params, ["delivery_address", "delivery_notes", "phone_number"])
      
      # Create order
      order_attrs = %{
        customer_id: user.id,
        restaurant_id: restaurant.id,
        total_price: cart_total,
        delivery_address: order_params["delivery_address"],
        delivery_notes: order_params["delivery_notes"],
        status: "pending"
      }
      
      # Create order items
      items_attrs = 
        Enum.map(cart_items, fn item ->
          %{
            meal_id: item.meal_id,
            quantity: item.quantity,
            customization_options: []
          }
        end)
      
      case Orders.create_order_with_items(order_attrs, items_attrs) do
        {:ok, order} ->
          # Process payment
          payment_attrs = %{
            amount: cart_total
          }
          
          case Orders.process_payment(order.id, payment_attrs) do
            {:ok, payment} ->
              socket = 
                socket
                |> assign(:order, order)
                |> assign(:payment, payment)
                |> assign(:step, :success)
                |> assign(:processing, false)
                |> put_flash(:info, "Order placed successfully!")
              
              {:noreply, socket}
            
            {:error, _reason} ->
              socket = 
                socket
                |> assign(:processing, false)
                |> put_flash(:error, "Payment failed. Please try again.")
              
              {:noreply, socket}
          end
        
        {:error, changeset} ->
          socket = 
            socket
            |> assign(:processing, false)
            |> put_flash(:error, "Failed to create order. Please check your details.")
          
          {:noreply, socket}
      end
    end
  end

  def handle_event("back_to_restaurant", _params, socket) do
    restaurant_id = socket.assigns.restaurant.id
    {:noreply, push_navigate(socket, to: ~p"/restaurants/#{restaurant_id}")}
  end

  def handle_event("continue_shopping", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  defp decode_cart(cart_param) do
    cart_param
    |> URI.decode()
    |> Jason.decode!()
    |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
    |> Map.new()
  rescue
    _ -> %{}
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

  defp format_order_number(order_id) do
    "##{String.pad_leading(to_string(order_id), 6, "0")}"
  end
end
