defmodule EatfairWeb.UserNavigation do
  @moduledoc """
  Unified navigation component that provides complete navigation functionality
  including theme toggle, authentication, and all user navigation features
  """
  use EatfairWeb, :html

  @doc """
  Renders unified navigation bar with theme toggle and all navigation features
  """
  attr :current_scope, :map, required: true

  def user_nav(assigns) do
    ~H"""
    <nav class="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700 transition-colors duration-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center h-16">
          <!-- Logo / Brand -->
          <div class="flex items-center">
            <.link 
              navigate={~p"/"} 
              class="flex items-center space-x-2 text-xl font-bold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 transition-colors"
            >
              <div class="w-8 h-8 bg-indigo-600 dark:bg-indigo-500 rounded-lg flex items-center justify-center">
                <span class="text-white font-bold text-sm">🍕</span>
              </div>
              <span>Eatfair</span>
            </.link>
          </div>

          <!-- Main Navigation -->
          <div class="hidden md:flex md:items-center md:space-x-4">
            <.link 
              navigate={~p"/restaurants/discover"} 
              class="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 px-3 py-2 rounded-md text-sm font-medium transition-colors"
            >
              Discover Restaurants
            </.link>

            <%= if @current_scope && @current_scope.user do %>
              <!-- Order Tracking -->
              <.link 
                navigate={~p"/orders/track"} 
                class="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 px-3 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Track Orders
              </.link>

              <!-- Restaurant Dashboard (if owner) -->
              <%= if @current_scope.user.role == "restaurant_owner" do %>
                <.link
                  navigate={~p"/restaurant/dashboard"}
                  class="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 px-3 py-2 rounded-md text-sm font-medium transition-colors"
                >
                  My Restaurant
                </.link>
              <% end %>

              <!-- User Greeting -->
              <span class="text-gray-700 dark:text-gray-300 text-sm">
                Hi, {@current_scope.user.name || String.split(@current_scope.user.email, "@") |> hd()}
              </span>

              <!-- User Dropdown -->
              <div class="relative" data-dropdown="user-menu">
                <button 
                  type="button"
                  class="flex items-center space-x-1 text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 px-3 py-2 rounded-md text-sm font-medium transition-colors"
                  onclick="toggleDropdown('user-menu')"
                >
                  <.icon name="hero-user-circle" class="w-5 h-5" />
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

              <!-- Theme Toggle -->
              <.theme_toggle />
            <% else %>
              <!-- Unauthenticated User Links -->
              <.link 
                navigate={~p"/users/log-in"} 
                class="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 px-3 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Log In
              </.link>
              
              <!-- Theme Toggle for unauthenticated users -->
              <.theme_toggle />
              
              <.link 
                navigate={~p"/users/register"} 
                class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Sign Up
              </.link>
            <% end %>
          </div>

          <!-- Mobile menu button -->
          <div class="sm:hidden">
            <button 
              type="button"
              class="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 p-2 transition-colors"
              onclick="toggleMobileMenu()"
            >
              <.icon name="hero-bars-3" class="w-6 h-6" />
            </button>
          </div>
        </div>

        <!-- Mobile Navigation -->
        <div id="mobile-menu" class="hidden sm:hidden pb-4">
          <div class="space-y-2">
            <.link 
              navigate={~p"/restaurants/discover"} 
              class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md transition-colors"
            >
              Discover Restaurants
            </.link>

            <%= if @current_scope && @current_scope.user do %>
              <.link 
                navigate={~p"/orders/track"} 
                class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md transition-colors"
              >
                Track Orders
              </.link>

              <%= if @current_scope.user.role == "restaurant_owner" do %>
                <.link
                  navigate={~p"/restaurant/dashboard"}
                  class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md transition-colors"
                >
                  My Restaurant
                </.link>
              <% end %>

              <.link 
                navigate={~p"/users/addresses"} 
                class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md transition-colors"
              >
                <.icon name="hero-map-pin" class="w-4 h-4 mr-2 inline" />
                Manage Addresses
              </.link>

              <.link 
                navigate={~p"/users/settings"} 
                class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md transition-colors"
              >
                Account Settings
              </.link>

              <.link 
                navigate={~p"/restaurant/onboard"}
                class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md transition-colors"
              >
                Start Your Restaurant
              </.link>

              <.link 
                href={~p"/users/log-out"} 
                method="delete"
                class="block px-3 py-2 text-base font-medium text-red-600 dark:text-red-400 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md transition-colors"
              >
                Log Out
              </.link>
            <% else %>
              <.link 
                navigate={~p"/users/log-in"} 
                class="block px-3 py-2 text-base font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-md transition-colors"
              >
                Log In
              </.link>
              
              <.link 
                navigate={~p"/users/register"} 
                class="block px-3 py-2 text-base font-medium bg-indigo-600 hover:bg-indigo-700 text-white rounded-md transition-colors"
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

  @doc """
  Theme toggle component - provides dark vs light theme toggle
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center border-2 border-gray-300 dark:border-gray-600 bg-gray-100 dark:bg-gray-700 rounded-full p-1 transition-colors">
      <button
        class="flex p-2 cursor-pointer rounded-full hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        title="System theme"
      >
        <.icon
          name="hero-computer-desktop"
          class="w-4 h-4 text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100"
        />
      </button>

      <button
        class="flex p-2 cursor-pointer rounded-full hover:bg-yellow-100 dark:hover:bg-yellow-700 transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        title="Light theme"
      >
        <.icon name="hero-sun" class="w-4 h-4 text-yellow-500 hover:text-yellow-600" />
      </button>

      <button
        class="flex p-2 cursor-pointer rounded-full hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        title="Dark theme"
      >
        <.icon
          name="hero-moon"
          class="w-4 h-4 text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100"
        />
      </button>
    </div>
    """
  end
end
