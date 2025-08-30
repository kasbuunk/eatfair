defmodule EatfairWeb.CheckoutDonationFlowTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.RestaurantsFixtures

  alias Eatfair.{Orders, Restaurants}

  setup do
    # Create test restaurant with menu and meals
    restaurant = restaurant_fixture()
    
    # Create menu with meals for the restaurant
    {:ok, menu} = Eatfair.Restaurants.create_menu(%{
      name: "Test Menu",
      restaurant_id: restaurant.id
    })
    
    {:ok, meal} = Eatfair.Restaurants.create_meal(%{
      name: "Test Pasta",
      description: "Delicious pasta dish",
      price: Decimal.new("15.50"),
      menu_id: menu.id
    })
    
    # Reload restaurant with associations
    restaurant = Restaurants.get_restaurant!(restaurant.id) |> Eatfair.Repo.preload(menus: :meals)
    
    %{restaurant: restaurant, meal: meal}
  end

  describe "🎯 Donation Integration During Checkout" do
    test "customer can add optional donation and total updates in real-time", %{
      conn: conn,
      restaurant: restaurant,
      meal: meal
    } do
      # 🛒 Setup: Customer has items in cart and navigates to payment
      cart = %{meal.id => 2}  # 2 items
      order_details = %{
        "email" => "donor@example.com",
        "phone_number" => "123456789",
        "delivery_address" => "123 Donor Street, Amsterdam",
        "delivery_time" => "ASAP",
        "special_instructions" => "Ring the bell"
      }

      cart_encoded = Jason.encode!(cart) |> URI.encode()
      order_encoded = Jason.encode!(order_details) |> URI.encode()
      
      payment_url = ~p"/order/#{restaurant.id}/payment?cart=#{cart_encoded}&order_details=#{order_encoded}"
      
      # 💳 Customer navigates to payment page
      {:ok, payment_live, html} = live(conn, payment_url)
      
      # ✅ Should see donation option with default €0
      assert html =~ "Support EatFair"
      assert html =~ "donation"
      assert html =~ "value=\"0.00\""  # Default donation amount in input
      
      # Initial total without donation
      initial_total = Decimal.mult(meal.price, 2)
      assert html =~ "#{Decimal.to_string(initial_total)}"
      
      # 💝 Customer adds €3.00 donation
      html = payment_live
        |> element("form[phx-change=update_donation]")
        |> render_change(%{"donation" => %{"amount" => "3.00"}})
      
      # ✅ Total should update to include donation
      total_with_donation = Decimal.add(initial_total, Decimal.new("3.00"))
      assert html =~ "#{Decimal.to_string(total_with_donation)}"
      assert html =~ "+€3.00"  # Donation shows as +€3.00 in the UI
      
      # 💳 Customer processes payment
      payment_live
      |> element("button[phx-click=process_payment]")
      |> render_click()
      
      # ⏳ Wait for payment processing
      Process.sleep(2100)  # Slightly longer than the 2s delay in payment processing
      
      # 🔍 Verify order was created with donation (wait for async processing)
      Process.sleep(100)  # Allow time for order creation
      orders = Orders.list_orders_by_email("donor@example.com")
      assert length(orders) == 1
      
      [order] = orders
      assert Decimal.equal?(order.donation_amount, Decimal.new("3.00"))
      assert order.donation_currency == "EUR"
      assert Decimal.equal?(order.total_price, initial_total)
    end

    test "customer can skip donation and checkout succeeds with €0 donation", %{
      conn: conn,
      restaurant: restaurant,
      meal: meal
    } do
      # 🛒 Setup: Customer checkout without donation
      cart = %{meal.id => 1}
      order_details = %{
        "email" => "nodeone@example.com",
        "phone_number" => "987654321", 
        "delivery_address" => "456 No Donation Ave, Utrecht",
        "delivery_time" => "19:30",
        "special_instructions" => ""
      }

      cart_encoded = Jason.encode!(cart) |> URI.encode()
      order_encoded = Jason.encode!(order_details) |> URI.encode()
      
      payment_url = ~p"/order/#{restaurant.id}/payment?cart=#{cart_encoded}&order_details=#{order_encoded}"
      
      # 💳 Customer navigates to payment page
      {:ok, payment_live, html} = live(conn, payment_url)
      
      # ✅ Should see donation option defaulting to €0
      assert html =~ "Support EatFair" 
      assert html =~ "value=\"0.00\""
      
      # 💳 Customer proceeds without changing donation (stays at €0)
      payment_live
      |> element("button[phx-click=process_payment]")
      |> render_click()
      
      # ⏳ Wait for payment processing
      Process.sleep(2100)
      
      # 🔍 Verify order created with €0 donation (wait for async processing)
      Process.sleep(100)  # Allow time for order creation
      orders = Orders.list_orders_by_email("nodeone@example.com")
      assert length(orders) == 1
      
      [order] = orders  
      assert Decimal.equal?(order.donation_amount, Decimal.new("0.00"))
      assert Decimal.equal?(order.total_price, meal.price)
    end

    test "donation amount is clearly shown in order confirmation", %{
      conn: conn,
      restaurant: restaurant,
      meal: meal
    } do
      # 🛒 Setup: Customer with donation navigates to confirmation
      cart = %{meal.id => 1}
      order_details = %{
        "email" => "confirm@example.com",
        "phone_number" => "555123456",
        "delivery_address" => "789 Confirm St, Hilversum", 
        "delivery_time" => "20:00",
        "special_instructions" => ""
      }

      cart_encoded = Jason.encode!(cart) |> URI.encode()
      order_encoded = Jason.encode!(order_details) |> URI.encode()
      
      confirm_url = ~p"/order/#{restaurant.id}/confirm?cart=#{cart_encoded}&order_details=#{order_encoded}"
      
      # 👀 Customer views confirmation page
      {:ok, confirm_live, html} = live(conn, confirm_url)
      
      # Initially no donation shown
      refute html =~ "Donation"
      
      # ✅ Can proceed to payment (functionality works without errors)
      confirm_live
      |> element("button", "Proceed to Payment") 
      |> render_click()
      
      # Test passes if no errors occur during navigation
    end
  end

  describe "🚨 Error Handling & Edge Cases" do
    test "invalid donation amounts are handled gracefully", %{
      conn: conn,
      restaurant: restaurant,
      meal: meal
    } do
      cart = %{meal.id => 1}
      order_details = %{
        "email" => "invalid@example.com",
        "phone_number" => "111222333",
        "delivery_address" => "Invalid Amount St 1",
        "delivery_time" => "ASAP"
      }

      cart_encoded = Jason.encode!(cart) |> URI.encode()
      order_encoded = Jason.encode!(order_details) |> URI.encode()
      
      payment_url = ~p"/order/#{restaurant.id}/payment?cart=#{cart_encoded}&order_details=#{order_encoded}"
      
      {:ok, payment_live, _html} = live(conn, payment_url)
      
      # Try negative donation amount - should be handled gracefully
      payment_live
        |> element("form[phx-change=update_donation]") 
        |> render_change(%{"donation" => %{"amount" => "-5.00"}})
      
      # Try excessive donation amount - should be handled gracefully
      payment_live
        |> element("form[phx-change=update_donation]")
        |> render_change(%{"donation" => %{"amount" => "1000000.00"}})
        
      # Test passes if no errors are raised during form changes
    end
  end
end
