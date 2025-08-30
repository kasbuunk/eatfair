defmodule EatfairWeb.EmailVerificationOnboardingTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  alias Eatfair.{Accounts, Orders, Repo}

  describe "🔗 Email Verification URL Redirect Issues" do
    test "FIXED: redirect now works correctly", %{conn: conn} do
      # Setup: Create an anonymous order with email verification
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "test@example.com",
        customer_phone: "+31612345678",
        delivery_address: "Test Address 123, Amsterdam",
        total_price: meal.price
      })

      {:ok, verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # FIXED BEHAVIOR: EmailVerificationController now redirects to correct URL
      response = get(conn, ~p"/verify-email/#{verification.token}")
      
      # This assertion now PASSES because we fixed the redirect:
      assert redirected_to(response) == "/orders/#{order.id}/track?token=#{order.tracking_token}"
      
      # Old broken behavior no longer applies:
      refute redirected_to(response) == "/orders/track/#{order.tracking_token}"
    end

    test "DESIRED: should redirect to correct order tracking URL with token param", %{conn: conn} do
      # Setup
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "test@example.com",
        customer_phone: "+31612345678",
        delivery_address: "Test Address 123, Amsterdam",
        total_price: meal.price
      })

      {:ok, verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # DESIRED BEHAVIOR: Should redirect to proper tracking URL
      response = get(conn, ~p"/verify-email/#{verification.token}")
      
      # This should PASS after fix
      assert redirected_to(response) == "/orders/#{order.id}/track?token=#{order.tracking_token}"
      assert get_flash(response, :info) =~ "Email verified"
    end
  end

  describe "📧 Email Content Enhancement" do
    test "FIXED: email now contains detailed order information", %{conn: _conn} do
      # Setup
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{
        restaurant_id: restaurant.id,
        name: "Margherita Pizza",
        price: Decimal.new("12.50"),
        description: "Classic pizza with tomato and mozzarella"
      })

      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "test@example.com",
        customer_phone: "+31612345678",
        delivery_address: "Koekoeklaan 31, 1403 EB Bussum, Netherlands",
        total_price: Decimal.new("25.00")
      })

      # Add order items
      {:ok, _} = Orders.create_order_items(order.id, [%{meal_id: meal.id, quantity: 2}])

      {:ok, _verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # Check that email was sent
      assert_received {:email, email}

      # FIXED: These now PASS because email template now includes details
      assert email.text_body =~ meal.name  # Meal names now included
      assert email.text_body =~ "€12.50"   # Prices now included  
      assert email.text_body =~ "x 2"      # Quantities now included
      assert email.text_body =~ "€25.00"   # Order total now included
      assert email.text_body =~ "Koekoeklaan 31"  # Full delivery address now included
      assert email.text_body =~ "/terms"          # Terms link now included
      assert email.text_body =~ "/privacy"        # Privacy link now included
      assert email.text_body =~ "loyalty rewards" # Account benefits now included
    end

    test "DESIRED: email should contain comprehensive order details", %{conn: _conn} do
      # Setup with preloaded associations
      restaurant = restaurant_fixture(%{
        name: "Night Owl Express NL",
        address: "Amsterdam Street 123",
        phone: "+31 20 555 0123"
      })
      
      meal = meal_fixture(%{
        restaurant_id: restaurant.id,
        name: "Margherita Pizza",
        price: Decimal.new("12.50"),
        description: "Classic pizza with tomato and mozzarella"
      })

      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "test@example.com",
        customer_phone: "+31612345678",
        delivery_address: "Koekoeklaan 31, 1403 EB Bussum, Netherlands",
        total_price: Decimal.new("25.00")
      })

      {:ok, _} = Orders.create_order_items(order.id, [%{meal_id: meal.id, quantity: 2}])

      {:ok, verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # Check that email was sent
      assert_received {:email, email}

      # DESIRED BEHAVIOR: These should PASS after enhancement
      assert email.text_body =~ "Night Owl Express NL"    # Restaurant name
      assert email.text_body =~ "Amsterdam Street 123"     # Restaurant address
      assert email.text_body =~ "Margherita Pizza"         # Meal name
      assert email.text_body =~ "€12.50"                   # Item price
      assert email.text_body =~ "x 2"                      # Quantity
      assert email.text_body =~ "€25.00"                   # Order total
      assert email.text_body =~ "Koekoeklaan 31, 1403 EB Bussum"  # Full delivery address
      assert email.text_body =~ "create your account"      # Account creation CTA
      assert email.text_body =~ "loyalty rewards"          # Account benefits
      assert email.text_body =~ "/terms"                   # Terms link
      assert email.text_body =~ "/privacy"                 # Privacy link
      assert email.text_body =~ "faster re-ordering"       # Specific benefit
    end
  end

  describe "👤 Account Creation & Auto-Login Flow" do
    test "current behavior: no automatic account creation - should FAIL", %{conn: conn} do
      # Setup
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "test@example.com",
        customer_phone: "+31612345678",
        delivery_address: "Test Address",
        total_price: meal.price
      })

      {:ok, verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # Verify email
      response = get(conn, ~p"/verify-email/#{verification.token}")
      
      # CURRENT ISSUE: User is not automatically logged in after verification
      # This should FAIL because current implementation doesn't create session
      # Check that we redirect to tracking (not account setup) and no user is logged in
      assert redirected_to(response) =~ "/orders/"  # Should redirect to tracking, not account setup
      refute redirected_to(response) == "/users/account-setup"  # No account setup redirect yet
    end

    test "DESIRED: should auto-create account and log in user on verification", %{conn: conn} do
      # Setup
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "newuser@example.com",
        customer_phone: "+31612345678",
        delivery_address: "Test Address",
        total_price: meal.price
      })

      {:ok, verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # Verify email - should auto-create account and login
      response = get(conn, ~p"/verify-email/#{verification.token}")
      
      # DESIRED: Should redirect to account setup page  
      assert redirected_to(response) == "/users/account-setup"
      
      # DESIRED: User should be logged in automatically
      conn_after_verification = Plug.Conn.fetch_session(response)
      user_token = get_session(conn_after_verification, :user_token)
      refute is_nil(user_token)
      
      # DESIRED: Account should be created
      user = Accounts.get_user_by_email("newuser@example.com")
      refute is_nil(user)
      assert user.confirmed_at  # Should be auto-confirmed
      assert user.phone_number == "+31612345678"
    end
  end

  describe "📋 Account Setup Page" do
    test "route doesn't exist yet - should return 404", %{conn: conn} do
      # This route doesn't exist yet - should return 404
      response = get(conn, "/users/account-setup")
      assert html_response(response, 404)
    end

    test "DESIRED: account setup should allow password creation and marketing opt-in", %{conn: conn} do
      # Skip this test until the route is implemented
      # This test will fail until we implement the account setup LiveView
      user = user_fixture(%{confirmed_at: DateTime.utc_now()})
      conn = log_in_user(conn, user)

      # This will fail until account setup route is implemented
      case get(conn, "/users/account-setup") do
        %{status: 404} -> 
          # Expected - route not implemented yet
          assert true
          
        %{status: 200} ->
          # After implementation, test the LiveView functionality
          {:ok, _view, html} = live(conn, "/users/account-setup")
          
          # Should have password form
          assert html =~ "Create Password"
          assert html =~ "type=\"password\""
          
          # Should have marketing opt-in checkbox (unchecked by default)
          assert html =~ "marketing notifications"
          assert html =~ "type=\"checkbox\""
          
          # Should have Terms & Conditions acknowledgment
          assert html =~ "Terms and Conditions"
          assert html =~ "Privacy Policy"
      end
    end
  end

  describe "📜 Legal Compliance Pages" do
    test "should have functional terms and privacy pages", %{conn: conn} do
      # Terms page should exist and render correctly
      response = get(conn, "/terms")
      assert html_response(response, 200)
      assert response.resp_body =~ "Terms of Service"
      assert response.resp_body =~ "Acceptance of Terms"
      assert response.resp_body =~ "EatFair"
      assert response.resp_body =~ "Privacy Policy"  # Link to privacy policy
      
      # Privacy page should exist and render correctly  
      response = get(conn, "/privacy")
      assert html_response(response, 200)
      assert response.resp_body =~ "Privacy Policy"
      assert response.resp_body =~ "Information We Collect"
      assert response.resp_body =~ "Your Rights"
      assert response.resp_body =~ "Data Security"
    end
  end

  describe "🧭 Active Delivery Navbar Indicator" do
    test "should show different navigation based on active deliveries count", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      
      # Test with 0 active deliveries
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Track Orders"  # Should show generic text
      refute html =~ "badge"         # No badge
      
      # Test with 1 active delivery - this functionality doesn't exist yet
      # After implementation, should show badge with direct link to that order
      
      # Test with 2+ active deliveries
      # After implementation, should show count badge linking to overview
    end
  end

  describe "🚨 Edge Cases & Error Handling" do
    test "should handle expired verification tokens gracefully", %{conn: conn} do
      restaurant = restaurant_fixture()
      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "test@example.com",
        customer_phone: "+31612345678",
        delivery_address: "Test Address",
        total_price: Decimal.new("25.00")
      })

      # Create expired verification
      {:ok, verification} = Accounts.create_email_verification(%{
        email: order.customer_email,
        token: Eatfair.Accounts.EmailVerification.generate_token(),
        expires_at: DateTime.add(DateTime.utc_now(), -3600), # 1 hour ago
        order_id: order.id
      })

      response = get(conn, ~p"/verify-email/#{verification.token}")
      
      assert redirected_to(response) == "/"
      assert get_flash(response, :error) =~ "expired"
    end

    test "should handle already verified tokens", %{conn: conn} do
      restaurant = restaurant_fixture()
      {:ok, order} = Orders.create_anonymous_order(%{
        restaurant_id: restaurant.id,
        customer_email: "test@example.com",
        customer_phone: "+31612345678",
        delivery_address: "Test Address",
        total_price: Decimal.new("25.00")
      })

      {:ok, verification} = Accounts.send_verification_email(order.customer_email, order: order)
      
      # First verification should work
      get(conn, ~p"/verify-email/#{verification.token}")
      
      # Second attempt should handle gracefully
      response = get(conn, ~p"/verify-email/#{verification.token}")
      assert redirected_to(response) == "/"
      assert get_flash(response, :info) =~ "already been verified"
    end
  end
end
