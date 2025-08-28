defmodule EatfairWeb.OrderFlowTest do
  use EatfairWeb.ConnCase, async: false
  use ExUnit.Case

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Ecto.Query

  alias Eatfair.{Repo, Restaurants}
  alias Eatfair.Orders.Order
  alias Eatfair.Restaurants.{Menu, Meal}

  describe "Complete order flow: User orders food for delivery" do
    setup do
      # Create test user
      user =
        user_fixture(%{
          email: "test@example.com",
          name: "Test User",
          phone_number: "555-0123"
        })

      # Create address with explicit coordinates that are close to restaurant
      {:ok, _address} =
        Eatfair.Accounts.create_address(%{
          "name" => "Home",
          "street_address" => "Damrak 1, Amsterdam",
          "city" => "Amsterdam",
          "postal_code" => "1012 LG",
          "country" => "Netherlands",
          # Very close to restaurant
          "latitude" => "52.3702",
          "longitude" => "4.8952",
          "is_default" => true,
          "user_id" => user.id
        })

      # Create test restaurant with owner
      owner =
        user_fixture(%{
          email: "owner@restaurant.com",
          name: "Restaurant Owner",
          role: :owner
        })

      {:ok, restaurant} =
        Restaurants.create_restaurant(%{
          name: "Test Pizza Place",
          # Close to user location
          address: "Nieuwmarkt 10, Amsterdam",
          latitude: Decimal.new("52.3702"),
          longitude: Decimal.new("4.9002"),
          # 5km delivery radius
          delivery_radius_km: 5,
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
      Repo.insert_all("restaurant_cuisines", [
        %{
          restaurant_id: restaurant.id,
          cuisine_id: cuisine.id,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      ])

      # Create menu for restaurant
      menu =
        Repo.insert!(%Menu{
          name: "Main Menu",
          restaurant_id: restaurant.id
        })

      # Create test meals
      meal1 =
        Repo.insert!(%Meal{
          name: "Margherita Pizza",
          description: "Classic pizza with tomato and mozzarella",
          price: Decimal.new("18.99"),
          is_available: true,
          menu_id: menu.id
        })

      meal2 =
        Repo.insert!(%Meal{
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

      # Navigate to restaurant discovery page where restaurants are listed
      {:ok, restaurants_view, _html} = live(conn, ~p"/restaurants")

      # Verify restaurant is displayed (restaurant names are in links, not h3 tags)
      assert has_element?(restaurants_view, "#restaurant-#{restaurant.id}")
      assert render(restaurants_view) =~ restaurant.name

      # Step 2: User clicks on restaurant to view details
      {:ok, restaurant_view, _html} =
        restaurants_view
        |> element("#restaurant-#{restaurant.id} a")
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

      # Step 4: User proceeds to order details (new flow)
      {:ok, details_view, _html} =
        restaurant_view
        |> element("[data-checkout-button]")
        |> render_click()
        |> follow_redirect(conn)

      # Verify order details page displays order items correctly
      assert has_element?(details_view, "[data-order-item]", meal1.name)
      # 2x pizza
      assert has_element?(details_view, "[data-item-quantity]", "2")
      assert has_element?(details_view, "[data-order-item]", meal2.name)
      # 1x salad
      assert has_element?(details_view, "[data-item-quantity]", "1")

      # Calculate expected total: (18.99 * 2) + (12.99 * 1) = 50.97
      expected_total = Decimal.new("50.97")
      assert has_element?(details_view, "[data-order-total]", "$50.97")

      # Step 5: User fills out delivery information
      delivery_address = "789 Delivery St, Test Town"
      phone_number = "555-9876"
      delivery_notes = "Ring the bell twice"

      details_view
      |> form("#checkout-form", %{
        "order" => %{
          "email" => "test@example.com",
          "delivery_address" => delivery_address,
          "phone_number" => phone_number,
          "special_instructions" => delivery_notes
        }
      })
      |> render_change()

      # Step 6: User submits the order details form to proceed to confirmation
      {:ok, confirm_view, _html} = 
        details_view
        |> form("#checkout-form")
        |> render_submit()
        |> follow_redirect(conn)

      # Step 7: Verify confirmation page shows order details
      assert has_element?(confirm_view, "h1", "Confirm Your Order")
      assert render(confirm_view) =~ delivery_address
      assert render(confirm_view) =~ phone_number

      # Step 8: User confirms the order and proceeds to payment
      initial_order_count = Repo.aggregate(Order, :count)

      {:ok, payment_view, _html} =
        confirm_view
        |> element("button", "Proceed to Payment")
        |> render_click()
        |> follow_redirect(conn)

      # Step 9: User processes payment
      payment_view
      |> element("[phx-click='process_payment']")
      |> render_click()

      # Wait for payment processing to complete - it's asynchronous with a 2-second delay
      # The payment process creates the order first, then updates its status after payment
      :timer.sleep(4000)
      
      # Step 10: Verify order was created successfully
      assert Repo.aggregate(Order, :count) == initial_order_count + 1

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
      assert order.special_instructions == delivery_notes
      assert Decimal.equal?(order.total_price, expected_total)
      assert order.status == "confirmed"

      # Verify order items
      # 2 different meals
      assert length(order.order_items) == 2

      pizza_item = Enum.find(order.order_items, &(&1.meal_id == meal1.id))
      salad_item = Enum.find(order.order_items, &(&1.meal_id == meal2.id))

      assert pizza_item.quantity == 2
      assert Decimal.equal?(pizza_item.meal.price, meal1.price)
      assert salad_item.quantity == 1
      assert Decimal.equal?(salad_item.meal.price, meal2.price)

      # Verify payment was created
      assert order.payment.amount == order.total_price
      assert order.payment.status == "completed"
    end

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

      # Go to order details (new flow)
      {:ok, details_view, _html} =
        restaurant_view
        |> element("[data-checkout-button]")
        |> render_click()
        |> follow_redirect(conn)

      # Try to submit without required delivery information
      initial_order_count = Repo.aggregate(Order, :count)

      # Form validation should prevent submission and show errors
      submit_result = details_view
      |> form("#checkout-form", %{
        "order" => %{
          "email" => "test@example.com",
          # Empty address
          "delivery_address" => "",
          # Empty phone
          "phone_number" => "",
          "special_instructions" => "Optional notes"
        }
      })
      |> render_submit()

      # Validation is working correctly if:
      # 1. render_submit returns HTML (doesn't redirect)
      # 2. The form stays on the same page 
      # 3. No order is created
      case submit_result do
        {:ok, _view, _html} ->
          # This means it redirected, which shouldn't happen with validation errors
          flunk("Form submitted successfully despite validation errors - should have validation errors")
        
        html when is_binary(html) ->
          # Form stayed on same page - this is correct validation behavior
          # The form should display the order details page, not redirect
          assert html =~ "Order Details" or html =~ "Essential Information"
      end

      # Verify order was NOT created
      assert Repo.aggregate(Order, :count) == initial_order_count
    end
  end
end
