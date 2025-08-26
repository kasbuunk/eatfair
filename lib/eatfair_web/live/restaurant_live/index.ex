defmodule EatfairWeb.RestaurantLive.Index do
  use EatfairWeb, :live_view

  alias Eatfair.LocationInference

  @impl true
  def mount(_params, _session, socket) do
    # Infer location for the user
    location_info = LocationInference.infer_location(socket)
    
    socket =
      socket
      |> assign(:page_title, "EatFair - Order Food Delivery")
      |> assign(:inferred_location, location_info.address)
      |> assign(:location_confidence, location_info.confidence)
      |> assign(:location_source, location_info.source)
      |> assign(:discover_location, "") # Start with empty field to show placeholder
      |> assign(:inferred_placeholder, location_info.address || "e.g. Amsterdam") # Use inferred location as placeholder
      |> assign(:should_request_geolocation, LocationInference.should_request_geolocation?(socket))

    # Request geolocation if we don't have a good location and haven't asked yet
    socket = 
      if location_info.confidence in [:none, :low] and LocationInference.should_request_geolocation?(socket) do
        # Push a JavaScript command to request geolocation after mount is complete
        Process.send_after(self(), :request_geolocation, 100)
        LocationInference.mark_geolocation_requested(socket)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_location", %{"location" => location}, socket) do
    {:noreply, assign(socket, :discover_location, location)}
  end

  @impl true
  def handle_event("input_change", %{"value" => query}, socket) do
    # Handle typing in address autocomplete - just update the location for now
    {:noreply, assign(socket, :discover_location, query)}
  end

  @impl true
  def handle_event("discover_restaurants", %{"location" => address}, socket) when is_binary(address) do
    # Use the current location or fall back to inferred location or Amsterdam
    final_location = 
      cond do
        String.trim(address) != "" -> address
        socket.assigns.inferred_location && String.trim(socket.assigns.inferred_location) != "" -> socket.assigns.inferred_location
        true -> "Amsterdam"
      end
    
    # Store the location in session for future inference
    socket = LocationInference.store_session_location(socket, final_location)
    
    # Navigate to discovery page with location parameter
    {:noreply, push_navigate(socket, to: ~p"/restaurants/discover?location=#{URI.encode(final_location)}")}
  end

  @impl true
  def handle_event("discover_restaurants", %{"location" => %{"address" => address}}, socket) do
    handle_event("discover_restaurants", %{"location" => address}, socket)
  end

  @impl true
  def handle_event("geolocation_success", %{"latitude" => _lat, "longitude" => _lng}, socket) do
    # Convert coordinates to a readable address (reverse geocoding)
    # For MVP, we'll just update placeholder to Amsterdam as fallback
    
    {:noreply,
     socket
     |> assign(:inferred_placeholder, "Amsterdam") # Update placeholder to Amsterdam for MVP
     |> assign(:location_confidence, :medium)
     |> assign(:location_source, :browser_geolocation)}
  end

  @impl true
  def handle_event("geolocation_error", %{"error" => _error}, socket) do
    # Geolocation failed or denied, fall back to IP-based inference
    {:noreply, socket}
  end

  @impl true
  def handle_info({"location_selected", selected_address}, socket) do
    # Store the selected address for the form submission
    {:noreply,
     socket
     |> assign(:discover_location, selected_address)
     |> LocationInference.store_session_location(selected_address)}
  end

  @impl true
  def handle_info(:request_geolocation, socket) do
    {:noreply, push_event(socket, "request_geolocation", %{})}
  end
end
