defmodule EatfairWeb.MenuLive.Preview do
  @moduledoc """
  LiveView for restaurant menu preview - shows how customers will see the menu.
  
  This allows restaurant owners to preview their menu exactly as customers
  would experience it, ensuring the layout and presentation meet their standards.
  """
  
  use EatfairWeb, :live_view
  
  alias Eatfair.Restaurants
  
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
         |> assign(:menus, menus)}
    end
  end
  
  @impl true
  def handle_event("return_to_edit", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/restaurant/menu")}
  end
  
  # Helper function to format price for display
  defp format_price(price) do
    "€#{:erlang.float_to_binary(Decimal.to_float(price), decimals: 2)}"
  end
  
  # Helper function to generate a data-test attribute from a string
  defp data_test_id(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
