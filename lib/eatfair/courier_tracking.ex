defmodule Eatfair.CourierTracking do
  @moduledoc """
  Courier location tracking and delivery coordination.
  
  This module provides foundation for:
  - Discrete state tracking (order picked up, delivered)
  - Continuous location streaming (GPS coordinates)
  - Delivery status management
  - ETA calculations based on real-time location
  
  Designed to be extensible for future courier integration while
  maintaining performance for real-time location updates.
  """

  alias Eatfair.{Orders, Notifications}
  alias Phoenix.PubSub
  
  @doc """
  Updates courier location for an order.
  
  Handles two types of updates:
  - Discrete state changes (picked_up, delivered) with notifications
  - Continuous location updates (GPS streaming) without excessive notifications
  """
  def update_courier_location(order_id, location_data) do
    case location_data do
      %{status: status} when status in ["picked_up", "at_customer", "delivered"] ->
        # Discrete state change - trigger notifications
        handle_discrete_status_change(order_id, status, location_data)
        
      %{latitude: lat, longitude: lon} ->
        # Continuous location update - stream position only
        handle_continuous_location_update(order_id, lat, lon, location_data)
    end
  end
  
  @doc """
  Gets current delivery status for an order.
  """
  def get_delivery_status(order_id) do
    # For MVP: Simple database lookup
    # Future: Redis cache for real-time performance
    case Orders.get_order!(order_id) do
      %{status: "out_for_delivery", courier_id: courier_id} = order when not is_nil(courier_id) ->
        %{
          order_id: order_id,
          courier_id: courier_id,
          status: "en_route",
          estimated_arrival: order.estimated_delivery_at,
          last_location_update: get_last_location_update(order_id)
        }
        
      %{status: "delivered"} ->
        %{
          order_id: order_id,
          status: "delivered",
          delivered_at: get_delivered_timestamp(order_id)
        }
        
      _ ->
        %{order_id: order_id, status: "not_assigned"}
    end
  end
  
  @doc """
  Streams location updates for active deliveries.
  
  Returns a stream of location updates for orders currently out for delivery.
  Useful for real-time tracking interfaces.
  """
  def stream_active_deliveries do
    # Future implementation: Stream from Redis/Phoenix.Presence
    # For MVP: Simple query with periodic updates
    active_orders = Orders.list_orders_out_for_delivery()
    
    Stream.map(active_orders, fn order ->
      %{
        order_id: order.id,
        customer_id: order.customer_id,
        courier_id: order.courier_id,
        estimated_arrival: order.estimated_delivery_at,
        current_status: determine_delivery_phase(order)
      }
    end)
  end
  
  @doc """
  Calculates ETA based on courier's current location.
  
  In production, this would integrate with mapping services.
  For MVP, uses simple distance-based calculation.
  """
  def calculate_delivery_eta(order_id, courier_lat, courier_lon) do
    order = Orders.get_order!(order_id)
    
    # Parse delivery address coordinates (future: geocoding service)
    # For MVP: Use restaurant location as proxy
    restaurant = order.restaurant
    
    case {restaurant.latitude, restaurant.longitude} do
      {rest_lat, rest_lon} when not is_nil(rest_lat) and not is_nil(rest_lon) ->
        # Calculate distance and estimated time
        distance_km = Eatfair.GeoUtils.calculate_distance(
          courier_lat, courier_lon,
          rest_lat, rest_lon
        )
        
        # Average delivery speed: 30 km/h in city
        travel_time_minutes = round(distance_km * 2)  # Conservative estimate
        
        NaiveDateTime.add(NaiveDateTime.utc_now(), travel_time_minutes * 60)
        
      _ ->
        # Fallback: Original estimated delivery time
        order.estimated_delivery_at
    end
  end
  
  # Private helper functions
  
  defp handle_discrete_status_change(order_id, status, location_data) do
    order = Orders.get_order!(order_id)
    
    case status do
      "picked_up" ->
        # Order has been picked up by courier
        broadcast_delivery_update(order, :picked_up, location_data)
        
        # Create high-priority notification
        Notifications.create_event(%{
          event_type: "delivery_update",
          recipient_id: order.customer_id,
          priority: "high",
          data: %{
            order_id: order_id,
            message: "Your order has been picked up and is on the way!",
            status: "picked_up",
            estimated_arrival: order.estimated_delivery_at
          }
        })
        
      "at_customer" ->
        # Courier has arrived at customer location
        broadcast_delivery_update(order, :arrived, location_data)
        
        Notifications.create_event(%{
          event_type: "delivery_update",
          recipient_id: order.customer_id,
          priority: "urgent",
          data: %{
            order_id: order_id,
            message: "Your delivery has arrived!",
            status: "arrived"
          }
        })
        
      "delivered" ->
        # Order has been delivered
        Orders.update_order_status(order, "delivered")
        broadcast_delivery_update(order, :delivered, location_data)
    end
  end
  
  defp handle_continuous_location_update(order_id, lat, lon, _location_data) do
    # Stream location updates without creating notifications for each update
    # This prevents notification spam while enabling real-time tracking
    
    location_update = %{
      order_id: order_id,
      latitude: lat,
      longitude: lon,
      timestamp: NaiveDateTime.utc_now()
    }
    
    # Broadcast to tracking channels only
    PubSub.broadcast(
      Eatfair.PubSub,
      "courier_location:#{order_id}",
      {:location_update, location_update}
    )
    
    # Update ETA if location has changed significantly
    order = Orders.get_order!(order_id)
    new_eta = calculate_delivery_eta(order_id, lat, lon)
    
    # Only update ETA if it has changed by more than 5 minutes
    if eta_changed_significantly?(order.estimated_delivery_at, new_eta) do
      Orders.update_order_status(order, order.status, %{
        estimated_delivery_at: new_eta
      })
    end
  end
  
  defp broadcast_delivery_update(order, status, location_data) do
    # Broadcast to customer
    PubSub.broadcast(
      Eatfair.PubSub,
      "order_tracking:#{order.customer_id}",
      {:delivery_update, order.id, status, location_data}
    )
    
    # Broadcast to restaurant
    PubSub.broadcast(
      Eatfair.PubSub,
      "restaurant_orders:#{order.restaurant_id}",
      {:delivery_update, order.id, status, location_data}
    )
  end
  
  defp get_last_location_update(_order_id) do
    # Future: Query from location tracking table/cache
    # For MVP: Return nil (no historical location data)
    nil
  end
  
  defp get_delivered_timestamp(order_id) do
    case Orders.get_order!(order_id) do
      %{delivered_at: timestamp} when not is_nil(timestamp) -> timestamp
      _ -> nil
    end
  end
  
  defp determine_delivery_phase(order) do
    # Analyze order timestamps to determine current delivery phase
    cond do
      order.delivered_at -> "delivered"
      order.out_for_delivery_at -> "en_route"
      order.ready_at -> "ready_for_pickup"
      true -> "unknown"
    end
  end
  
  defp eta_changed_significantly?(old_eta, new_eta) do
    case {old_eta, new_eta} do
      {nil, _} -> true
      {_, nil} -> false
      {old, new} ->
        diff_minutes = abs(NaiveDateTime.diff(new, old, :minute))
        diff_minutes > 5
    end
  end
end
