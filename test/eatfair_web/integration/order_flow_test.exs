defmodule EatfairWeb.OrderFlowTest do
  use EatfairWeb.ConnCase, async: true
  use ExUnit.Case

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Ecto.Query

  alias Eatfair.{Accounts, Orders, Restaurants, Repo}
  alias Eatfair.Orders.{Order, OrderItem, Payment}
  alias Eatfair.Restaurants.{Restaurant, Cuisine, Menu, Meal}

  describe "Complete order flow: User orders food for delivery" do
    setup do
      # Create test user
      user = user_fixture(%{
        email: "test@example.com",
        name: "Test User",
        phone_number: "555-0123",
        default_address: "123 Test St, Test City"
      })

      # Create test restaurant with owner
      owner = user_fixture(%{
        email: "owner@restaurant.com",
        name: "Restaurant Owner",
        role: :owner
      })

      {:ok, restaurant} = Restaurants.create_restaurant(%{
          name: "Test Pizza Place",
          address: "456 Pizza Ave, Food City",
          delivery_time: 40,
          min_order_value: Decimal.new("15.00"),
          is_open: true,
          rating: Decimal.new("4.5"),
          image_url: "https://example.com/pizza.jpg",
          owner_id: owner.id
        })

      # Create cuisine and associate with restaurant
      {:ok, cuisine} = Restaurants.create_cuisine(%{name: "Italian"})
      
      # Associate restaurant with cuisine directly via repo
      Repo.insert_all("restaurant_cuisines", [%{
        restaurant_id: restaurant.id, 
        cuisine_id: cuisine.id,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }])

      # Create menu for restaurant
      menu = Repo.insert!(%Menu{
        name: "Main Menu",
        restaurant_id: restaurant.id
      })

      # Create test meals
      meal1 = Repo.insert!(%Meal{
        name: "Margherita Pizza",
        description: "Classic pizza with tomato and mozzarella",
        price: Decimal.new("18.99"),
        is_available: true,
        menu_id: menu.id
      })

      meal2 = Repo.insert!(%Meal{
        name: "Caesar Salad",
        description: "Fresh romaine with parmesan and croutons",
        price: Decimal.new("12.99"),
        is_available: true,
        menu_id: menu.id
      })

      %{
        user: user,
        restaurant: restaurant,
        cuisine: cuisine,
        menu: menu,
        meal1: meal1,
        meal2: meal2
      }
    end

    test "user can browse restaurants, add items to cart, and complete order", %{
      conn: conn,
      user: user,
      restaurant: restaurant,
      meal1: meal1,
      meal2: meal2
    } do
      # Step 1: User logs in and browses restaurants
      conn = log_in_user(conn, user)
      
      {:ok, restaurants_view, _html} = live(conn, ~p"/")
      
      # Verify restaurant is displayed
      assert has_element?(restaurants_view, "h3", restaurant.name)
      assert has_element?(restaurants_view, "span", "4.5")
      
      # Step 2: User clicks on restaurant to view details
      {:ok, restaurant_view, _html} = 
        restaurants_view
        |> element("#restaurants-#{restaurant.id}")
        |> render_click()
        |> follow_redirect(conn)

      # Verify restaurant details and menu items are displayed
      assert has_element?(restaurant_view, "h1", restaurant.name)
      assert has_element?(restaurant_view, "[data-meal-name]", meal1.name)
      assert has_element?(restaurant_view, "[data-meal-name]", meal2.name)
      assert has_element?(restaurant_view, "[data-meal-price]", "$18.99")
      assert has_element?(restaurant_view, "[data-meal-price]", "$12.99")

      # Step 3: User adds items to cart
      # Add 2x Margherita Pizza
      restaurant_view
      |> element("[data-meal-id='#{meal1.id}'] [data-add-to-cart]")
      |> render_click()
      
      restaurant_view
      |> element("[data-meal-id='#{meal1.id}'] [data-add-to-cart]")
      |> render_click()

      # Add 1x Caesar Salad
      restaurant_view
      |> element("[data-meal-id='#{meal2.id}'] [data-add-to-cart]")
      |> render_click()

      # Verify cart is updated (3 items total)
      assert has_element?(restaurant_view, "[data-cart-count]", "3")
      
      # Step 4: User proceeds to checkout
      {:ok, checkout_view, _html} = 
        restaurant_view
        |> element("[data-checkout-button]")
        |> render_click()
        |> follow_redirect(conn)

      # Verify checkout page displays order items correctly
      assert has_element?(checkout_view, "[data-order-item]", meal1.name)
      assert has_element?(checkout_view, "[data-item-quantity]", "2")  # 2x pizza
      assert has_element?(checkout_view, "[data-order-item]", meal2.name) 
      assert has_element?(checkout_view, "[data-item-quantity]", "1")  # 1x salad

      # Calculate expected total: (18.99 * 2) + (12.99 * 1) = 50.97
      expected_total = Decimal.new("50.97")
      assert has_element?(checkout_view, "[data-order-total]", "$50.97")

      # Step 5: User fills out delivery information
      delivery_address = "789 Delivery St, Test Town"
      phone_number = "555-9876"
      delivery_notes = "Ring the bell twice"

      checkout_view
      |> form("#checkout-form", %{
        "delivery_address" => delivery_address,
        "phone_number" => phone_number,
        "delivery_notes" => delivery_notes
      })
      |> render_change()

      # Step 6: User places the order
      initial_order_count = Repo.aggregate(Order, :count)
      initial_payment_count = Repo.aggregate(Payment, :count)

      checkout_view
      |> form("#checkout-form")
      |> render_submit()

      # Step 7: Verify order was created successfully
      assert Repo.aggregate(Order, :count) == initial_order_count + 1
      assert Repo.aggregate(Payment, :count) == initial_payment_count + 1

      # Get the created order
      order = 
        Order
        |> where([o], o.customer_id == ^user.id)
        |> order_by([o], desc: o.inserted_at)
        |> limit(1)
        |> Repo.one()
        |> Repo.preload([:payment, :restaurant, order_items: :meal])

      # Verify order details
      assert order.customer_id == user.id
      assert order.restaurant_id == restaurant.id
      assert order.delivery_address == delivery_address
      assert order.delivery_notes == delivery_notes
      assert Decimal.equal?(order.total_price, expected_total)
      assert order.status == "confirmed"

      # Verify order items
      assert length(order.order_items) == 2  # 2 different meals

      pizza_item = Enum.find(order.order_items, &(&1.meal_id == meal1.id))
      salad_item = Enum.find(order.order_items, &(&1.meal_id == meal2.id))

      assert pizza_item.quantity == 2
      assert Decimal.equal?(pizza_item.meal.price, meal1.price)
      assert salad_item.quantity == 1
      assert Decimal.equal?(salad_item.meal.price, meal2.price)

      # Verify payment was created
      assert order.payment.amount == order.total_price
      assert order.payment.status == "completed"

      # Step 8: Verify success page/message is shown
      assert has_element?(checkout_view, "[data-success-message]")
      assert has_element?(checkout_view, "h1", "Order Confirmed!")
    end

    @tag :skip
    test "user cannot place order with invalid delivery information", %{
      conn: conn,
      user: user,
      restaurant: restaurant,
      meal1: meal1
    } do
      conn = log_in_user(conn, user)
      
      # Navigate to restaurant and add item to cart
      {:ok, restaurant_view, _html} = live(conn, ~p"/restaurants/#{restaurant.id}")
      
      restaurant_view
      |> element("[data-meal-id='#{meal1.id}'] [data-add-to-cart]")
      |> render_click()

      # Go to checkout
      {:ok, checkout_view, _html} = 
        restaurant_view
        |> element("[data-checkout-button]")
        |> render_click()
        |> follow_redirect(conn)

      # Try to submit without required delivery information
      initial_order_count = Repo.aggregate(Order, :count)

      checkout_view
      |> form("#checkout-form", %{
        "delivery_address" => "",  # Empty address
        "phone_number" => "",      # Empty phone
        "delivery_notes" => "Optional notes"
      })
      |> render_submit()

      # Verify order was NOT created
      assert Repo.aggregate(Order, :count) == initial_order_count

      # Verify error messages are shown
      assert has_element?(checkout_view, "[data-error]")
    end
  end
end
