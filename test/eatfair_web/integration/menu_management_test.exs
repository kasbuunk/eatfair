defmodule EatfairWeb.Integration.MenuManagementTest do
  @moduledoc """
  Integration tests for the complete Menu Management Journey.
  
  This test suite implements the project specification requirement:
  "Menu Management: Full menu creation, editing, categorization, and pricing control"
  
  The tests tell the delightful story of how restaurant owners create and manage 
  their menus with excellence, preparing their offerings for hungry customers.
  """
  
  use EatfairWeb.ConnCase
  import Phoenix.LiveViewTest
  
  alias Eatfair.{Accounts, Restaurants}

  describe "🍽️ The Menu Creation Journey: From Concept to Customer" do
    test "Sarah builds her complete dumpling menu with categories and customization readiness" do
      # 📖 Chapter 1: Sarah has already onboarded her restaurant (existing flow works!)
      {:ok, user} = Accounts.register_user(%{
        email: "sarah@dumplingdreams.com", 
        password: "SecurePassword123!",
        name: "Sarah Chen"
      })
      
      {:ok, restaurant} = Restaurants.create_restaurant(%{
        name: "Sarah's Authentic Dumplings",
        address: "123 Maple Street, Het Gooi, Netherlands",
        description: "Traditional handmade dumplings passed down through generations.",
        cuisine_types: ["Asian/International"],
        owner_id: user.id
      })
      
      # She logs in and accesses her restaurant dashboard
      conn = log_in_user(build_conn(), user)
      {:ok, dashboard_live, _html} = live(conn, "/restaurant/dashboard")
      
      # 📖 Chapter 2: Sarah discovers the menu management section
      # She sees a clear call-to-action to create her first menu
      assert has_element?(dashboard_live, "[data-test='manage-menus-link']")
      assert has_element?(dashboard_live, "[data-test='create-first-menu']")
      
      # She clicks to start building her menu
      menu_live = 
        dashboard_live
        |> element("[data-test='manage-menus-link']")
        |> render_click()
        |> follow_redirect(conn, "/restaurant/menu")
      
      {:ok, menu_live, _html} = 
        case menu_live do
          {:ok, live, html} -> {:ok, live, html}
          {:ok, %Plug.Conn{} = conn} -> live(conn, "/restaurant/menu")
          %Plug.Conn{} = conn -> live(conn, "/restaurant/menu")
        end
      
      # 📖 Chapter 3: The inspiring menu creation interface
      # Sarah sees a welcoming, organized interface for building her menu
      assert has_element?(menu_live, "[data-test='menu-management-dashboard']")
      assert has_element?(menu_live, "h1", "Menu Management")
      
      # For first-time users, she sees helpful guidance
      assert has_element?(menu_live, "[data-test='empty-menu-state']")
      assert has_element?(menu_live, "[data-test='add-first-menu-section']")
      
      # 📖 Chapter 4: Creating menu categories (sections)
      # Sarah wants to organize her dumplings properly: Appetizers, Mains, Desserts
      
      # She creates her first menu section - "Appetizers"
      menu_live
      |> element("[data-test='add-first-menu-section']")
      |> render_click()
      
      assert has_element?(menu_live, "[data-test='menu-section-form']")
      
      menu_live
      |> form("[data-test='menu-section-form']", menu: %{"name" => "Appetizers"})
      |> render_submit()
      
      # The appetizer section appears immediately (LiveView magic!)
      assert has_element?(menu_live, "[data-test='menu-section-appetizers']")
      assert has_element?(menu_live, "[data-test='section-title']", "Appetizers")
      
      # 📖 Chapter 5: Adding menu items to categories
      # Now Sarah can add her famous pan-fried dumplings
      
      assert has_element?(menu_live, "[data-test='add-menu-item-appetizers']")
      
      menu_live
      |> element("[data-test='add-menu-item-appetizers']")
      |> render_click()
      
      assert has_element?(menu_live, "[data-test='menu-item-form']")
      
      # She fills in her signature dish details
      dumpling_data = %{
        "name" => "Pan-Fried Pork Dumplings",
        "description" => "Crispy bottom, tender top. Made fresh daily with grandmother's secret seasoning blend. Served with our house-made soy-ginger dipping sauce.",
        "price" => "8.50"
      }
      
      menu_live
      |> form("[data-test='menu-item-form']", meal: dumpling_data)
      |> render_submit()
      
      # The dumpling appears in the appetizers section immediately!
      assert has_element?(menu_live, "[data-test='menu-item-pan-fried-pork-dumplings']")
      assert has_element?(menu_live, "[data-test='item-name']", "Pan-Fried Pork Dumplings")
      assert has_element?(menu_live, "[data-test='item-price']", "€8.50")
      assert has_element?(menu_live, "[data-test='item-description']", "Crispy bottom, tender top")
      
      # The item is available by default
      assert has_element?(menu_live, "[data-test='item-available-toggle'][data-available='true']")
      
      # 📖 Chapter 6: Quick item management controls
      # Sarah can toggle availability without deleting items
      
      menu_live
      |> element("[data-test='item-available-toggle']")
      |> render_click()
      
      # Item immediately shows as unavailable with visual feedback
      assert has_element?(menu_live, "[data-test='item-available-toggle'][data-available='false']")
      assert has_element?(menu_live, "[data-test='menu-item-pan-fried-pork-dumplings'][data-status='unavailable']")
      
      # She can toggle it back on
      menu_live
      |> element("[data-test='item-available-toggle']")
      |> render_click()
      
      assert has_element?(menu_live, "[data-test='item-available-toggle'][data-available='true']")
      
      # 📖 Chapter 7: Building a complete menu structure
      # Sarah adds more sections and items to create a full menu
      
      # Add "Main Courses" section
      menu_live
      |> element("[data-test='add-menu-section-button']")
      |> render_click()
      
      menu_live
      |> form("[data-test='menu-section-form']", menu: %{"name" => "Main Courses"})
      |> render_submit()
      
      # Add a main course item
      menu_live
      |> element("[data-test='add-menu-item-main-courses']")
      |> render_click()
      
      main_dish_data = %{
        "name" => "Dumpling Feast Platter",
        "description" => "A generous selection of our best dumplings: pork, chicken, and vegetable. Perfect for sharing!",
        "price" => "24.00"
      }
      
      menu_live
      |> form("[data-test='menu-item-form']", meal: main_dish_data)
      |> render_submit()
      
      # Both sections now display with their items
      assert has_element?(menu_live, "[data-test='menu-section-appetizers']")
      assert has_element?(menu_live, "[data-test='menu-section-main-courses']")
      assert has_element?(menu_live, "[data-test='menu-item-dumpling-feast-platter']")
      
      # 📖 Chapter 8: Menu preview functionality
      # Sarah wants to see how customers will experience her menu
      
      assert has_element?(menu_live, "[data-test='preview-menu-button']")
      
      preview_live = 
        menu_live
        |> element("[data-test='preview-menu-button']")
        |> render_click()
        |> follow_redirect(conn, "/restaurant/menu/preview")
      
      {:ok, preview_live, html} = 
        case preview_live do
          {:ok, live, html} -> {:ok, live, html}
          {:ok, %Plug.Conn{} = conn} -> live(conn, "/restaurant/menu/preview")
          %Plug.Conn{} = conn -> live(conn, "/restaurant/menu/preview")
        end
      
      # The preview shows exactly what customers will see
      assert has_element?(preview_live, "[data-test='customer-menu-view']")
      assert html =~ "Pan-Fried Pork Dumplings"
      assert html =~ "€8.50"
      assert html =~ "Dumpling Feast Platter"
      assert html =~ "€24.00"
      
      # Organized by sections for easy browsing
      assert has_element?(preview_live, "[data-test='menu-section-appetizers-customer']")
      assert has_element?(preview_live, "[data-test='menu-section-main-courses-customer']")
      
      # 📖 Chapter 9: Easy editing and management
      # Sarah can return to edit mode to make changes
      
      assert has_element?(preview_live, "[data-test='return-to-edit-button']")
      
      edit_live = 
        preview_live
        |> element("[data-test='return-to-edit-button']")
        |> render_click()
        |> follow_redirect(conn, "/restaurant/menu")
      
      {:ok, edit_live, _html} = 
        case edit_live do
          {:ok, live, html} -> {:ok, live, html}
          {:ok, %Plug.Conn{} = conn} -> live(conn, "/restaurant/menu")
          %Plug.Conn{} = conn -> live(conn, "/restaurant/menu")
        end
      
      # All her menu structure is preserved
      assert has_element?(edit_live, "[data-test='menu-item-pan-fried-pork-dumplings']")
      assert has_element?(edit_live, "[data-test='menu-item-dumpling-feast-platter']")
      
      # 📖 Verification: The database reflects Sarah's menu creation work
      restaurant_menus = Restaurants.get_restaurant_menus(restaurant.id)
      assert length(restaurant_menus) >= 2  # At least appetizers and main courses
      
      all_meals = Restaurants.get_available_meals(restaurant.id)
      assert length(all_meals) >= 2  # At least the two items she created
      
      dumpling_meal = Enum.find(all_meals, &(&1.name == "Pan-Fried Pork Dumplings"))
      assert Decimal.equal?(dumpling_meal.price, Decimal.new("8.50"))
      assert dumpling_meal.is_available == true
      
      # 📖 Epilogue: Future-ready for customizations
      # The data model supports future meal customization features
      # but keeps the interface simple and focused for now
      
      assert dumpling_meal.description =~ "grandmother's secret seasoning"
    end

    test "restaurant owner can edit existing menu items seamlessly" do
      # This test covers the edit functionality for menu items
      
      user = insert(:user, name: "Marco Rossi")
      restaurant = insert(:restaurant, owner_id: user.id, name: "Marco's Pizzeria")
      
      # Create initial menu structure through the context (simulating existing menu)
      {:ok, appetizers_menu} = Restaurants.create_menu(%{
        name: "Appetizers",
        restaurant_id: restaurant.id
      })
      
      {:ok, garlic_bread} = Restaurants.create_meal(%{
        name: "Garlic Bread",
        description: "Fresh baked bread with garlic butter",
        price: "5.50",
        menu_id: appetizers_menu.id
      })
      
      conn = log_in_user(build_conn(), user)
      {:ok, menu_live, _html} = live(conn, "/restaurant/menu")
      
      # Marco sees his existing menu item
      assert has_element?(menu_live, "[data-test='menu-item-garlic-bread']")
      
      # He clicks to edit it
      menu_live
      |> element("[data-test='edit-menu-item-garlic-bread']")
      |> render_click()
      
      assert has_element?(menu_live, "[data-test='menu-item-form-edit']")
      
      # He updates the description and price
      updated_data = %{
        "name" => "Artisan Garlic Bread",
        "description" => "Freshly baked sourdough with roasted garlic and herb butter. A customer favorite!",
        "price" => "6.00"
      }
      
      menu_live
      |> form("[data-test='menu-item-form-edit']", meal: updated_data)
      |> render_submit()
      
      # The changes appear immediately
      assert has_element?(menu_live, "[data-test='item-name']", "Artisan Garlic Bread")
      assert has_element?(menu_live, "[data-test='item-price']", "€6.00")
      assert has_element?(menu_live, "[data-test='item-description']", "customer favorite")
      
      # Database is updated
      updated_meal = Restaurants.get_meal!(garlic_bread.id)
      assert updated_meal.name == "Artisan Garlic Bread"
      assert Decimal.equal?(updated_meal.price, Decimal.new("6.00"))
    end

    test "menu validates required fields while being user-friendly" do
      # Ensure quality standards without frustrating users
      
      user = insert(:user)
      _restaurant = insert(:restaurant, owner_id: user.id)
      conn = log_in_user(build_conn(), user)
      
      {:ok, menu_live, _html} = live(conn, "/restaurant/menu")
      
      # Try to create menu section without name
      menu_live
      |> element("[data-test='add-first-menu-section']")
      |> render_click()
      
      menu_live
      |> form("[data-test='menu-section-form']", menu: %{"name" => ""})
      |> render_submit()
      
      # User-friendly error guidance
      assert has_element?(menu_live, "[data-test='menu-section-form']")
      # The form should show validation feedback
      
      # Try to create menu item without required fields
      # First create a valid section
      menu_live
      |> form("[data-test='menu-section-form']", menu: %{"name" => "Test Section"})
      |> render_submit()
      
      menu_live
      |> element("[data-test='add-menu-item-test-section']")
      |> render_click()
      
      # Submit with missing required fields
      menu_live
      |> form("[data-test='menu-item-form']", meal: %{"name" => "", "price" => ""})
      |> render_submit()
      
      # Should show validation without being overwhelming
      assert has_element?(menu_live, "[data-test='menu-item-form']")
      
      # Description should be optional (not overwhelming)
      valid_item = %{
        "name" => "Simple Item",
        "price" => "10.00"
      }
      
      menu_live
      |> form("[data-test='menu-item-form']", meal: valid_item)
      |> render_submit()
      
      # Should succeed without description
      assert has_element?(menu_live, "[data-test='menu-item-simple-item']")
    end
  end

  # Test helper functions
  defp insert(factory, attrs \\ %{}) do
    case factory do
      :user -> 
        default_attrs = %{
          email: "user#{System.unique_integer()}@example.com",
          password: "ValidPassword123!",
          name: "Test User"
        }
        merged_attrs = Map.merge(default_attrs, Enum.into(attrs, %{}))
        {:ok, user} = Accounts.register_user(merged_attrs)
        user
        
      :restaurant ->
        default_attrs = %{
          name: "Test Restaurant",
          address: "123 Test Street",
          cuisine_types: ["Local/European"]
        }
        merged_attrs = Map.merge(default_attrs, Enum.into(attrs, %{}))
        {:ok, restaurant} = Restaurants.create_restaurant(merged_attrs)
        restaurant
    end
  end
end
