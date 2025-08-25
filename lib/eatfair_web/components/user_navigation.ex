defmodule EatfairWeb.UserNavigation do
  @moduledoc """
  User navigation component that provides access to user account features
  """
  use EatfairWeb, :html

  @doc """
  Renders user navigation with dropdown menu for authenticated users
  """
  attr :current_scope, :map, required: true

  def user_nav(assigns) do
    ~H"""
    <nav class="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center h-16">
          <!-- Logo / Brand -->
          <div class="flex-shrink-0">
            <.link navigate={~p"/"} class="flex items-center">
              <span class="text-2xl font-bold text-indigo-600 dark:text-indigo-400">🍽️ EatFair</span>
            </.link>
          </div>

          <!-- Main Navigation -->
          <div class="hidden md:flex md:items-center md:space-x-6">
            <.link 
              navigate={~p"/restaurants/discover"} 
              class="text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 px-3 py-2 text-sm font-medium transition-colors"
            >
              Discover Restaurants
            </.link>

            <%= if @current_scope && @current_scope.user do %>
              <!-- Order Tracking -->
              <.link 
                navigate={~p"/orders/track"} 
                class="text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 px-3 py-2 text-sm font-medium transition-colors"
              >
                Track Orders
              </.link>

              <!-- User Dropdown -->
              <div class="relative" data-dropdown="user-menu">
                <button 
                  type="button"
                  class="flex items-center space-x-2 text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 px-3 py-2 text-sm font-medium transition-colors"
                  onclick="toggleDropdown('user-menu')"
                >
                  <.icon name="hero-user-circle" class="w-5 h-5" />
                  <span>{@current_scope.user.email |> String.split("@") |> List.first()}</span>
                  <.icon name="hero-chevron-down" class="w-4 h-4" />
                </button>

                <!-- Dropdown Menu -->
                <div 
                  id="user-menu-dropdown"
                  class="hidden absolute right-0 mt-2 w-56 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-50"
                >
                  <div class="py-2">
                    <.link 
                      navigate={~p"/users/addresses"} 
                      class="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    >
                      <.icon name="hero-map-pin" class="w-4 h-4 mr-3" />
                      Manage Addresses
                    </.link>

                    <.link 
                      navigate={~p"/users/settings"} 
                      class="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    >
                      <.icon name="hero-cog-6-tooth" class="w-4 h-4 mr-3" />
                      Account Settings
                    </.link>

                    <.link 
                      navigate={~p"/restaurant/onboard"} 
                      class="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    >
                      <.icon name="hero-building-storefront" class="w-4 h-4 mr-3" />
                      Start Your Restaurant
                    </.link>

                    <hr class="my-1 border-gray-200 dark:border-gray-600" />
                    
                    <.link 
                      href={~p"/users/log-out"} 
                      method="delete"
                      class="flex items-center px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    >
                      <.icon name="hero-arrow-right-on-rectangle" class="w-4 h-4 mr-3" />
                      Log Out
                    </.link>
                  </div>
                </div>
              </div>
            <% else %>
              <!-- Unauthenticated User Links -->
              <.link 
                navigate={~p"/users/log-in"} 
                class="text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 px-3 py-2 text-sm font-medium transition-colors"
              >
                Log In
              </.link>
              
              <.link 
                navigate={~p"/users/register"} 
                class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors"
              >
                Sign Up
              </.link>
            <% end %>
          </div>

          <!-- Mobile menu button -->
          <div class="md:hidden">
            <button 
              type="button"
              class="text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400"
              onclick="toggleMobileMenu()"
            >
              <.icon name="hero-bars-3" class="w-6 h-6" />
            </button>
          </div>
        </div>

        <!-- Mobile Navigation -->
        <div id="mobile-menu" class="hidden md:hidden pb-4">
          <div class="space-y-2">
            <.link 
              navigate={~p"/restaurants/discover"} 
              class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md"
            >
              Discover Restaurants
            </.link>

            <%= if @current_scope && @current_scope.user do %>
              <.link 
                navigate={~p"/orders/track"} 
                class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md"
              >
                Track Orders
              </.link>

              <.link 
                navigate={~p"/users/addresses"} 
                class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md"
              >
                <.icon name="hero-map-pin" class="w-4 h-4 mr-2 inline" />
                Manage Addresses
              </.link>

              <.link 
                navigate={~p"/users/settings"} 
                class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md"
              >
                Account Settings
              </.link>

              <.link 
                href={~p"/users/log-out"} 
                method="delete"
                class="block px-3 py-2 text-base font-medium text-red-600 dark:text-red-400 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md"
              >
                Log Out
              </.link>
            <% else %>
              <.link 
                navigate={~p"/users/log-in"} 
                class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md"
              >
                Log In
              </.link>
              
              <.link 
                navigate={~p"/users/register"} 
                class="block px-3 py-2 text-base font-medium bg-indigo-600 hover:bg-indigo-700 text-white rounded-md"
              >
                Sign Up
              </.link>
            <% end %>
          </div>
        </div>
      </div>
    </nav>

    <script>
      function toggleDropdown(menuId) {
        const dropdown = document.getElementById(menuId + '-dropdown');
        dropdown.classList.toggle('hidden');
        
        // Close dropdown when clicking outside
        document.addEventListener('click', function(event) {
          const menu = document.querySelector('[data-dropdown="' + menuId + '"]');
          if (!menu.contains(event.target)) {
            dropdown.classList.add('hidden');
          }
        }, { once: true });
      }

      function toggleMobileMenu() {
        const menu = document.getElementById('mobile-menu');
        menu.classList.toggle('hidden');
      }
    </script>
    """
  end
end
