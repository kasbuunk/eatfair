defmodule EatfairWeb.RestaurantLive.Onboarding do
  @moduledoc """
  Restaurant onboarding LiveView that transforms users into empowered restaurant owners.
  
  Implements the project specification's core value:
  "Entrepreneur Empowerment: Every feature should strengthen local restaurant owners' 
  ability to build sustainable businesses"
  
  This LiveView creates an inspiring, simple onboarding experience that respects 
  the user's time while collecting essential business information.
  """
  
  use EatfairWeb, :live_view
  
  alias Eatfair.{Restaurants, FileUpload}
  alias Eatfair.Restaurants.Restaurant
  
  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    
    # Check if user already owns a restaurant
    case Restaurants.get_user_restaurant(user.id) do
      nil ->
        # New restaurant owner - show onboarding
        changeset = Restaurants.change_restaurant(%Restaurant{}, %{owner_id: user.id})
        
        socket =
          socket
          |> assign(:changeset, changeset)
          |> assign(:form, to_form(changeset))
          |> assign(:page_title, "Start Your Restaurant Journey")
          |> assign(:uploaded_files, [])
          |> allow_upload(:restaurant_image, 
               accept: FileUpload.allowed_extensions(), 
               max_entries: 1, 
               max_file_size: FileUpload.max_file_size())
        
        {:ok, socket}
        
      _restaurant ->
        # User already has restaurant - redirect to dashboard
        {:ok, redirect(socket, to: ~p"/restaurant/dashboard")}
    end
  end
  
  @impl true
  def handle_event("validate", %{"restaurant" => restaurant_params}, socket) do
    changeset =
      %Restaurant{}
      |> Restaurant.changeset(restaurant_params)
      |> Map.put(:action, :validate)
    
    {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
  end
  
  @impl true
  def handle_event("save", %{"restaurant" => restaurant_params}, socket) do
    user = socket.assigns.current_scope.user
    
    # Add owner_id to params
    restaurant_params = Map.put(restaurant_params, "owner_id", user.id)
    
    # Handle image upload if present
    restaurant_params = maybe_upload_image(socket, restaurant_params)
    
    case Restaurants.create_restaurant(restaurant_params) do
      {:ok, restaurant} ->
        # Success! Restaurant owner is born 🎉
        socket =
          socket
          |> put_flash(:info, "🎉 Welcome to EatFair! Your restaurant is now live and ready for customers.")
          |> redirect(to: ~p"/restaurant/dashboard")
        
        {:noreply, socket}
        
      {:error, %Ecto.Changeset{} = changeset} ->
        # Show friendly errors to guide success
        {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
    end
  end
  
  # Handle file upload progress and validation
  @impl true
  def handle_event("validate_upload", _params, socket) do
    # Validate uploaded files
    uploaded_entries = socket.assigns.uploads.restaurant_image.entries
    
    errors = 
      Enum.flat_map(uploaded_entries, fn entry ->
        case FileUpload.validate_upload(entry) do
          :ok -> []
          {:error, errors} -> errors
        end
      end)
    
    socket = 
      if errors != [] do
        put_flash(socket, :error, "Image upload errors: #{Enum.join(errors, ", ")}")
      else
        clear_flash(socket, :error)
      end
    
    {:noreply, socket}
  end
  
  # Handle file upload cancellation
  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :restaurant_image, ref)}
  end
  
  # Helper to handle optional image upload
  defp maybe_upload_image(socket, restaurant_params) do
    case uploaded_entries(socket, :restaurant_image) do
      {[], []} ->
        # No image uploaded
        restaurant_params
        
      {[entry], []} ->
        # Image uploaded - save it
        case FileUpload.save_upload(entry, "restaurants") do
          {:ok, image_url} ->
            Map.put(restaurant_params, "image_url", image_url)
          {:error, _reason} ->
            # Log error but don't fail onboarding
            restaurant_params
        end
        
      _ ->
        # Multiple files or errors - skip for now
        restaurant_params
    end
  end
end
