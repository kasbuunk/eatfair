defmodule EatfairWeb.RestaurantLive.ProfileEdit do
  @moduledoc """
  Restaurant profile editing LiveView.

  Allows restaurant owners to update their business information, ensuring they 
  maintain full control over their brand and customer relationships.
  """

  use EatfairWeb, :live_view

  alias Eatfair.{Restaurants, FileUpload}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    case Restaurants.get_user_restaurant(user.id) do
      nil ->
        # No restaurant - guide to onboarding
        {:ok, redirect(socket, to: ~p"/restaurant/onboard")}

      restaurant ->
        # Restaurant owner - show edit form
        changeset = Restaurants.change_restaurant(restaurant)

        socket =
          socket
          |> assign(:restaurant, restaurant)
          |> assign(:changeset, changeset)
          |> assign(:form, to_form(changeset))
          |> assign(:page_title, "Edit #{restaurant.name}")
          |> allow_upload(:restaurant_image,
            accept: FileUpload.allowed_extensions(),
            max_entries: 1,
            max_file_size: FileUpload.max_file_size()
          )

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"restaurant" => restaurant_params}, socket) do
    changeset =
      socket.assigns.restaurant
      |> Restaurants.change_restaurant(restaurant_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"restaurant" => restaurant_params}, socket) do
    restaurant = socket.assigns.restaurant

    # Handle image upload if present
    restaurant_params = maybe_upload_image(socket, restaurant_params)

    case Restaurants.update_restaurant(restaurant, restaurant_params) do
      {:ok, _updated_restaurant} ->
        socket =
          socket
          |> put_flash(:info, "Restaurant profile updated successfully!")
          |> redirect(to: ~p"/restaurant/dashboard")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :restaurant_image, ref)}
  end

  # Helper to handle optional image upload
  defp maybe_upload_image(socket, restaurant_params) do
    case uploaded_entries(socket, :restaurant_image) do
      {[], []} ->
        # No new image uploaded - keep existing
        restaurant_params

      {[entry], []} ->
        # New image uploaded - save it and delete old one
        case FileUpload.save_upload(socket, :restaurant_image, entry, "restaurants") do
          {:ok, image_url} ->
            # Delete old image if it exists
            if socket.assigns.restaurant.image_url do
              FileUpload.delete_file(socket.assigns.restaurant.image_url)
            end

            Map.put(restaurant_params, "image_url", image_url)
        end

      _ ->
        # Error case - keep existing
        restaurant_params
    end
  end
end
