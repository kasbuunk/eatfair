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
      # Start with empty field to show placeholder
      |> assign(:discover_location, "")
      # Use inferred location as placeholder
      |> assign(:inferred_placeholder, location_info.address || "e.g. Amsterdam")
      |> assign(
        :should_request_geolocation,
        LocationInference.should_request_geolocation?(socket)
      )

    # Request geolocation if we don't have a good location and haven't asked yet
    # But only if we're not in a test environment
    socket =
      if location_info.confidence in [:none, :low] and
           LocationInference.should_request_geolocation?(socket) and not test_environment?() do
        # Only request geolocation in production/development to avoid test issues
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
  def handle_event("discover_restaurants", %{"location" => location}, socket) do
    # Handle form submission with location parameter
    final_location =
      cond do
        is_binary(location) && String.trim(location) != "" ->
          String.trim(location)

        socket.assigns.discover_location && String.trim(socket.assigns.discover_location) != "" ->
          String.trim(socket.assigns.discover_location)

        socket.assigns.inferred_location && String.trim(socket.assigns.inferred_location) != "" ->
          socket.assigns.inferred_location

        true ->
          "Amsterdam"
      end

    # Store the location in session for future inference
    socket = LocationInference.store_session_location(socket, final_location)

    # Navigate to discovery page - let ~p handle URL encoding to avoid double encoding
    {:noreply, push_navigate(socket, to: ~p"/restaurants?#{[location: final_location]}")}
  end

  @impl true
  def handle_event("update_location_from_form", %{"location" => location}, socket) do
    # Handle real-time form changes to sync the location state
    require Logger
    Logger.debug("🔍 Form change! location: #{inspect(location)}")
    {:noreply, assign(socket, :discover_location, location || "")}
  end

  @impl true
  def handle_event("handle_keydown", %{"key" => "Enter"}, socket) do
    # Handle Enter key in the input field
    final_location =
      if socket.assigns.discover_location && String.trim(socket.assigns.discover_location) != "" do
        String.trim(socket.assigns.discover_location)
      else
        socket.assigns.inferred_location || "Amsterdam"
      end

    socket = LocationInference.store_session_location(socket, final_location)
    {:noreply, push_navigate(socket, to: ~p"/restaurants?#{[location: final_location]}")}
  end

  @impl true
  def handle_event("handle_keydown", _params, socket) do
    # Ignore other keydown events
    {:noreply, socket}
  end

  @impl true
  def handle_event("geolocation_success", %{"latitude" => _lat, "longitude" => _lng}, socket) do
    # Convert coordinates to a readable address (reverse geocoding)
    # For MVP, we'll just update placeholder to Amsterdam as fallback
    # Don't show any error messages for geolocation success

    {:noreply,
     socket
     # Update placeholder to Amsterdam for MVP
     |> assign(:inferred_placeholder, "Amsterdam")
     |> assign(:location_confidence, :medium)
     |> assign(:location_source, :browser_geolocation)}
  end

  @impl true
  def handle_event("geolocation_error", %{"error" => error}, socket) do
    # Geolocation failed or denied, fall back to IP-based inference
    # Don't propagate geolocation errors to the user - handle gracefully
    # Log the error for debugging but don't show error messages
    require Logger
    Logger.debug("Geolocation error: #{error}")
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
  def handle_info({"input_change", query}, socket) do
    # Handle typing in the address autocomplete to keep parent state in sync
    require Logger
    Logger.debug("🔍 Received input_change: #{inspect(query)}")
    {:noreply, assign(socket, :discover_location, query)}
  end

  @impl true
  def handle_info(:request_geolocation, socket) do
    if not test_environment?() do
      {:noreply, push_event(socket, "request_geolocation", %{})}
    else
      {:noreply, socket}
    end
  end

  # Helper to detect test environment
  defp test_environment?() do
    Application.get_env(:eatfair, :environment) == :test or
      Mix.env() == :test or
      Code.ensure_loaded?(ExUnit)
  end
end
