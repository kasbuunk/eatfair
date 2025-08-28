defmodule EatfairWeb.OrderLive.Success do
  use EatfairWeb, :live_view

  alias Eatfair.Orders

  @impl true
  def mount(%{"id" => order_id}, _session, socket) do
    order = Orders.get_order!(order_id)
    
    socket = 
      socket
      |> assign(:order, order)
      |> assign(:estimated_delivery_time, calculate_estimated_delivery(order))
      
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("track_order", _params, socket) do
    # In a real implementation, this would redirect to an order tracking page
    # For now, we'll just show a flash message
    {:noreply, put_flash(socket, :info, "Order tracking will be available soon!")}
  end

  def handle_event("order_again", _params, socket) do
    restaurant_id = socket.assigns.order.restaurant_id
    {:noreply, push_navigate(socket, to: ~p"/restaurants/#{restaurant_id}")}
  end

  def handle_event("browse_restaurants", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/restaurants")}
  end

  defp calculate_estimated_delivery(order) do
    # Calculate based on restaurant prep time + delivery time
    prep_time_minutes = order.restaurant.avg_preparation_time || 30
    delivery_time_minutes = 20  # Estimated delivery time
    total_minutes = prep_time_minutes + delivery_time_minutes
    
    DateTime.add(DateTime.utc_now(), total_minutes * 60)
  end

  defp format_price(price) do
    "$#{Decimal.to_float(price) |> :erlang.float_to_binary(decimals: 2)}"
  end

  defp format_order_number(order_id) do
    "##{String.pad_leading(to_string(order_id), 6, "0")}"
  end
end
