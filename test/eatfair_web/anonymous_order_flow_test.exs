defmodule EatfairWeb.AnonymousOrderFlowTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.RestaurantsFixtures
  import Eatfair.OrdersFixtures

  alias Eatfair.{Orders, Accounts}

  describe "Anonymous Order Flow" do
    setup do
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id, price: Decimal.new("12.50")})

      %{
        restaurant: restaurant,
        meal: meal,
        cart: %{meal.id => 2},
        cart_total: Decimal.new("25.00"),
        order_details: %{
          "email" => "test@example.com",
          "phone_number" => "+31-6-12345678",
          "delivery_address" => "Test Street 123, 1012 AB Amsterdam",
          "delivery_time" => "ASAP",
          "special_instructions" => "Ring the bell twice"
        }
      }
    end

    test "anonymous order creation generates tracking token and soft account", %{
      conn: _conn,
      restaurant: restaurant,
      meal: _meal,
      cart: cart,
      order_details: order_details
    } do
      # Test the core functionality directly through the Orders context
      order_attrs = %{
        restaurant_id: restaurant.id,
        customer_email: order_details["email"],
        customer_phone: order_details["phone_number"],
        delivery_address: order_details["delivery_address"],
        special_instructions: order_details["special_instructions"],
        total_price: Decimal.new("25.00"),
        status: "pending"
      }

      # Create anonymous order (this should generate tracking token)
      {:ok, order} = Orders.create_anonymous_order(order_attrs)

      # Add order items
      items_attrs =
        Enum.map(cart, fn {meal_id, quantity} ->
          %{meal_id: meal_id, quantity: quantity}
        end)

      {:ok, _items} = Orders.create_order_items(order.id, items_attrs)

      # Reload order with associations
      order = Orders.get_order!(order.id)

      # CRITICAL ASSERTION: Order should have tracking token
      assert order.tracking_token != nil
      assert String.length(order.tracking_token) > 10

      # CRITICAL ASSERTION: Order should be associated with soft account
      assert order.customer_id != nil
      assert order.customer_email == "test@example.com"

      # Send verification email and verify it works
      {:ok, _verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # CRITICAL ASSERTION: Email verification should be created
      email_verification =
        Accounts.get_verification_by_email(order.customer_email)

      assert email_verification != nil
      assert email_verification.order_id == order.id
    end

    test "anonymous user can track order using tracking token", %{
      conn: conn,
      restaurant: restaurant,
      meal: _meal,
      cart: cart,
      order_details: order_details
    } do
      # First create an order with tracking token
      {:ok, order} = create_anonymous_order_with_tracking_token(restaurant, cart, order_details)

      # Navigate to order success page
      {:ok, success_view, _html} = live(conn, "/order/success/#{order.id}")

      # Click "Track Order" button
      success_view
      |> element("button", "Track Order")
      |> render_click()

      # Should redirect to tracking page with token
      expected_path = "/orders/#{order.id}/track?token=#{order.tracking_token}"
      assert_redirected(success_view, expected_path)

      # Navigate to tracking page and ensure it renders
      {:ok, _tracking_view, html} = live(conn, expected_path)

      # Should show order tracking information
      assert html =~ "Order ##{order.id}"
      assert html =~ order.delivery_address
    end

    test "email verification contains tracking link", %{
      conn: _conn,
      restaurant: restaurant,
      meal: _meal,
      cart: cart,
      order_details: order_details
    } do
      # Create order
      {:ok, order} = create_anonymous_order_with_tracking_token(restaurant, cart, order_details)

      # Send verification email
      {:ok, _verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # Check that verification email was sent to test mailbox
      # Note: This assumes Swoosh test adapter is configured in test.exs
      assert_received {:email, email}

      assert email.to == [{"", order.customer_email}]
      assert email.subject =~ "track your EatFair order"
      assert email.text_body =~ "/orders/track/#{order.tracking_token}"
      assert email.text_body =~ "Order ##{order.id}"
    end

    test "anonymous user gets error message when tracking token is missing", %{conn: conn} do
      # Create order without tracking token (simulating the bug)
      order = order_fixture(%{tracking_token: nil, customer_email: "test@example.com"})

      {:ok, view, _html} = live(conn, "/order/success/#{order.id}")

      # Click track order button
      view
      |> element("button", "Track Order")
      |> render_click()

      # Should show error flash and stay on same page
      html = render(view)
      assert html =~ "Order tracking is not available for this order"
    end
  end

  # Helper functions
  defp create_anonymous_order_with_tracking_token(restaurant, cart, order_details) do
    # This should use the fixed Orders.create_anonymous_order/1 function
    order_attrs = %{
      restaurant_id: restaurant.id,
      customer_email: order_details["email"],
      customer_phone: order_details["phone_number"],
      delivery_address: order_details["delivery_address"],
      special_instructions: order_details["special_instructions"],
      total_price: Decimal.new("25.00"),
      status: "confirmed"
    }

    items_attrs =
      Enum.map(cart, fn {meal_id, quantity} ->
        %{meal_id: meal_id, quantity: quantity}
      end)

    case Orders.create_anonymous_order(order_attrs) do
      {:ok, order} ->
        # Add order items
        {:ok, _items} = Orders.create_order_items(order.id, items_attrs)

        # Reload order with associations
        order = Orders.get_order!(order.id)
        {:ok, order}

      error ->
        error
    end
  end
end
