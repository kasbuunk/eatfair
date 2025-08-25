defmodule EatfairWeb.MenuLive.Management do
  @moduledoc """
  LiveView for restaurant menu management.
  
  This module allows restaurant owners to:
  - Create and organize menu sections (categories)
  - Add, edit, and manage menu items
  - Toggle item availability in real-time
  - Preview their menu as customers see it
  
  Designed with extensibility in mind for future meal customization features.
  """
  
  use EatfairWeb, :live_view
  
  alias Eatfair.Restaurants
  alias Eatfair.Restaurants.{Menu, Meal}
  
  @impl true
  def mount(_params, _session, socket) do
    # Ensure user owns a restaurant
    current_user = socket.assigns.current_scope.user
    
    case Restaurants.get_user_restaurant(current_user.id) do
      nil ->
        {:ok, 
         socket
         |> put_flash(:error, "Please complete restaurant onboarding first.")
         |> push_navigate(to: ~p"/restaurant/onboard")}
         
      restaurant ->
        menus = Restaurants.get_restaurant_menus(restaurant.id)
        
        {:ok, 
         socket
         |> assign(:restaurant, restaurant)
         |> assign(:menus, menus)
         |> assign(:show_menu_form, false)
         |> assign(:show_meal_form, nil)  # nil = no form, menu_id = show form for that menu
         |> assign(:editing_meal, nil)   # nil = not editing, meal = editing that meal
         |> assign(:menu_form, to_form(Restaurants.change_menu(%Menu{})))
         |> assign(:meal_form, to_form(Restaurants.change_meal(%Meal{})))}
    end
  end
  
  @impl true
  def handle_event("show_menu_form", _params, socket) do
    {:noreply, assign(socket, :show_menu_form, true)}
  end
  
  @impl true
  def handle_event("hide_menu_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_menu_form, false)
     |> assign(:menu_form, to_form(Restaurants.change_menu(%Menu{})))}
  end
  
  @impl true
  def handle_event("create_menu", %{"menu" => menu_params}, socket) do
    menu_params = Map.put(menu_params, "restaurant_id", socket.assigns.restaurant.id)
    
    case Restaurants.create_menu(menu_params) do
      {:ok, menu} ->
        updated_menus = Restaurants.get_restaurant_menus(socket.assigns.restaurant.id)
        
        {:noreply, 
         socket
         |> assign(:menus, updated_menus)
         |> assign(:show_menu_form, false)
         |> assign(:menu_form, to_form(Restaurants.change_menu(%Menu{})))
         |> put_flash(:info, "Menu section \"#{menu.name}\" created successfully!")}
         
      {:error, changeset} ->
        {:noreply, assign(socket, :menu_form, to_form(changeset))}
    end
  end
  
  @impl true
  def handle_event("show_meal_form", %{"menu_id" => menu_id}, socket) do
    menu_id = String.to_integer(menu_id)
    {:noreply, assign(socket, :show_meal_form, menu_id)}
  end
  
  @impl true
  def handle_event("hide_meal_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_meal_form, nil)
     |> assign(:meal_form, to_form(Restaurants.change_meal(%Meal{})))}
  end
  
  @impl true
  def handle_event("create_meal", %{"meal" => meal_params, "menu_id" => menu_id}, socket) do
    meal_params = Map.put(meal_params, "menu_id", menu_id)
    
    case Restaurants.create_meal(meal_params) do
      {:ok, _meal} ->
        updated_menus = Restaurants.get_restaurant_menus(socket.assigns.restaurant.id)
        
        {:noreply, 
         socket
         |> assign(:menus, updated_menus)
         |> assign(:show_meal_form, nil)
         |> assign(:meal_form, to_form(Restaurants.change_meal(%Meal{})))
         |> put_flash(:info, "Menu item \"#{meal_params["name"]}\" added successfully!")}
         
      {:error, changeset} ->
        {:noreply, assign(socket, :meal_form, to_form(changeset))}
    end
  end
  
  @impl true
  def handle_event("edit_meal", %{"meal_id" => meal_id}, socket) do
    meal = Restaurants.get_meal!(meal_id)
    changeset = Restaurants.change_meal(meal)
    
    {:noreply, 
     socket
     |> assign(:editing_meal, meal)
     |> assign(:meal_form, to_form(changeset))
     |> assign(:show_meal_form, nil)}  # Close any open meal forms
  end
  
  @impl true
  def handle_event("cancel_edit_meal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:editing_meal, nil)
     |> assign(:meal_form, to_form(Restaurants.change_meal(%Meal{})))}
  end
  
  @impl true
  def handle_event("update_meal", %{"meal" => meal_params}, socket) do
    meal = socket.assigns.editing_meal
    
    case Restaurants.update_meal(meal, meal_params) do
      {:ok, updated_meal} ->
        updated_menus = Restaurants.get_restaurant_menus(socket.assigns.restaurant.id)
        
        {:noreply, 
         socket
         |> assign(:menus, updated_menus)
         |> assign(:editing_meal, nil)
         |> assign(:meal_form, to_form(Restaurants.change_meal(%Meal{})))
         |> put_flash(:info, "Menu item \"#{updated_meal.name}\" updated successfully!")}
         
      {:error, changeset} ->
        {:noreply, assign(socket, :meal_form, to_form(changeset))}
    end
  end
  
  @impl true
  def handle_event("toggle_meal_availability", %{"meal_id" => meal_id}, socket) do
    meal = Restaurants.get_meal!(meal_id)
    
    case Restaurants.update_meal(meal, %{is_available: !meal.is_available}) do
      {:ok, _updated_meal} ->
        updated_menus = Restaurants.get_restaurant_menus(socket.assigns.restaurant.id)
        
        status_message = if meal.is_available do
          "\"#{meal.name}\" is now unavailable"
        else
          "\"#{meal.name}\" is now available"
        end
        
        {:noreply, 
         socket
         |> assign(:menus, updated_menus)
         |> put_flash(:info, status_message)}
         
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to update availability")}
    end
  end
  
  @impl true
  def handle_event("preview_menu", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/restaurant/menu/preview")}
  end
  
  # Helper function to generate a data-test attribute from a string
  defp data_test_id(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
  
  # Helper function to format price for display
  defp format_price(price) do
    "€#{:erlang.float_to_binary(Decimal.to_float(price), decimals: 2)}"
  end
end
