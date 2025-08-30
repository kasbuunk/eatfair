defmodule EatfairWeb.AccountSetupFlowTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.RestaurantsFixtures

  alias Eatfair.{Accounts, Orders}

  describe "🎯 Account Setup Button Functionality" do
    setup %{conn: conn} do
      # Create a complete order flow with email verification
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "test@example.com",
          customer_phone: "+31612345678",
          delivery_address: "Test Address 123, Amsterdam",
          total_price: meal.price
        })

      {:ok, verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # Simulate email verification flow that logs user in and redirects to account setup
      verification_response = get(conn, ~p"/verify-email/#{verification.token}")
      assert redirected_to(verification_response) == "/users/account-setup"

      # Use the connection with the session from email verification
      conn = verification_response
      user = Accounts.get_user_by_email("test@example.com")

      %{conn: conn, user: user, order: order}
    end

    test "Complete Account Setup button redirects to order tracking", %{
      conn: conn,
      user: user,
      order: order
    } do
      {:ok, view, _html} = live(conn, "/users/account-setup")

      # Fill in password fields with terms acceptance
      view
      |> form("#account_setup_form",
        user: %{
          name: "John Doe",
          password: "validpassword123",
          password_confirmation: "validpassword123"
        },
        terms_accepted: "true"
      )
      |> render_submit()

      # Should redirect to order tracking for this specific order
      assert_redirected(view, ~p"/orders/#{order.id}/track?token=#{order.tracking_token}")

      # Verify password was set
      updated_user = Accounts.get_user!(user.id)
      assert Eatfair.Accounts.User.valid_password?(updated_user, "validpassword123")
    end

    test "Complete Account Setup without password redirects to order tracking", %{
      conn: conn,
      order: order
    } do
      {:ok, view, _html} = live(conn, "/users/account-setup")

      # Submit form without password but with terms and marketing opt-in
      view
      |> form("#account_setup_form",
        user: %{name: "Jane Doe", password: "", password_confirmation: ""},
        marketing_opt_in: "true",
        terms_accepted: "true"
      )
      |> render_submit()

      # Should still redirect to order tracking 
      assert_redirected(view, ~p"/orders/#{order.id}/track?token=#{order.tracking_token}")
    end

    test "Agree and continue without password button redirects to order tracking", %{
      conn: conn,
      order: order
    } do
      {:ok, view, _html} = live(conn, "/users/account-setup")

      # Click the skip/continue button (phx-click="skip")
      view |> element("button[phx-click=skip]") |> render_click()

      # Should redirect to order tracking immediately, bypassing terms validation
      assert_redirected(view, ~p"/orders/#{order.id}/track?token=#{order.tracking_token}")
    end

    test "handles case where user has no recent order gracefully", %{conn: conn, user: user} do
      # Delete the order to simulate edge case
      Orders.delete_order(Orders.get_latest_customer_order(user.id))

      {:ok, view, _html} = live(conn, "/users/account-setup")

      # Click skip button when no order exists
      view |> element("button[phx-click=skip]") |> render_click()

      # Should fallback to general order tracking overview
      assert_redirected(view, ~p"/orders/track")
    end
  end

  describe "🎨 Enhanced Account Setup UX Flow" do
    setup %{conn: conn} do
      # Create complete order flow with email verification to match real user journey
      restaurant = restaurant_fixture()
      meal = meal_fixture(%{restaurant_id: restaurant.id})

      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "ux_test@example.com",
          customer_phone: "+31612345678",
          delivery_address: "Test Address 123, 1012 AB Amsterdam",
          total_price: meal.price
        })

      {:ok, verification} = Accounts.send_verification_email(order.customer_email, order: order)

      # Simulate email verification flow
      verification_response = get(conn, ~p"/verify-email/#{verification.token}")
      conn = verification_response
      user = Accounts.get_user_by_email("ux_test@example.com")

      %{conn: conn, user: user, order: order}
    end

    test "revised subtitle copy removes anonymous language", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/account-setup")

      # Should NOT contain misleading "continue anonymously" text 
      refute html =~ "continue anonymously"
      
      # Should contain new, clearer messaging
      assert html =~ "Secure your account or continue without a password — both give you full access"
    end

    test "visual separator clearly denotes two equivalent flows", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/account-setup")

      # Should have visual separator with OR text
      assert html =~ ~r/<div[^>]*or-separator[^>]*>.*OR.*<\/div>/s
    end

    test "name field is present and required", %{conn: conn} do
      {:ok, view, html} = live(conn, "/users/account-setup")

      # Should have name input field
      assert html =~ "name=\"user[name]\""
      assert html =~ "Full Name"

      # Should be required and validated
      view
      |> form("#account_setup_form",
        user: %{
          name: "",  # Empty name should fail validation
          password: "validpassword123", 
          password_confirmation: "validpassword123"
        },
        terms_accepted: "true"
      )
      |> render_submit()

      # Should show validation error for missing name
      html = render(view)
      assert html =~ "can't be blank" || html =~ "required"
    end

    test "delivery address fields are prefilled from order data", %{conn: conn, order: _order} do
      {:ok, _view, html} = live(conn, "/users/account-setup")

      # Should have delivery address fieldset
      assert html =~ "Delivery Address"
      
      # Should have address input fields prefilled from order
      assert html =~ "Test Address 123"  # Street from order.delivery_address
      assert html =~ "1012 AB"          # Postal code from order.delivery_address 
      assert html =~ "Amsterdam"        # City from order.delivery_address
    end

    test "invoice address same-as-delivery checkbox controls field visibility", %{conn: conn} do
      {:ok, view, html} = live(conn, "/users/account-setup")

      # Should have "Same as delivery" checkbox (default checked)
      assert html =~ "same_as_delivery"
      assert html =~ "checked"
      
      # Invoice address fields should initially be hidden/disabled
      # When unchecked, should show separate invoice address fields
      
      view
      |> form("#account_setup_form", same_as_delivery: "false")
      |> render_change()
      
      html = render(view)
      
      # Should now show invoice address fieldset
      assert html =~ "Invoice Address"
      assert html =~ "invoice_street_address"
    end

    test "single terms acceptance checkpoint for both flows", %{conn: conn} do
      {:ok, view, html} = live(conn, "/users/account-setup")

      # Should have only ONE terms acceptance checkbox
      assert html =~ "name=\"terms_accepted\""
      # Count occurrences of terms_accepted to ensure it's not duplicated
      terms_count = (html |> String.split("name=\"terms_accepted\"") |> length()) - 1
      assert terms_count == 1
      
      # Should be positioned above both CTA buttons, not duplicated below
      refute html =~ ~r/Complete.*Setup.*By continuing you agree/s  # No terms after buttons

      # Both flows should be blocked without terms acceptance
      view
      |> form("#account_setup_form",
        user: %{name: "Test User", password: "", password_confirmation: ""}
        # Not including terms_accepted means it's unchecked
      )
      |> render_submit()

      # Should remain on page with error
      html = render(view)
      assert html =~ "must accept" || html =~ "Terms and Conditions"
    end

    test "both flows persist user data and redirect to order tracking", %{conn: conn, order: order} do
      {:ok, view, _html} = live(conn, "/users/account-setup")

      # Test password flow
      view
      |> form("#account_setup_form",
        user: %{
          name: "John Doe",
          password: "securepassword123", 
          password_confirmation: "securepassword123"
        },
        marketing_opt_in: "true",
        terms_accepted: "true"
      )
      |> render_submit()

      # Should redirect to order tracking
      assert_redirected(view, ~p"/orders/#{order.id}/track?token=#{order.tracking_token}")
      
      # Should persist user name and marketing preference
      user = Accounts.get_user_by_email("ux_test@example.com")
      assert user.name == "John Doe"
      # TODO: Assert marketing opt-in when persistence implemented
    end

    test "passwordless flow also persists data and creates valid account", %{conn: conn, order: order} do
      {:ok, view, _html} = live(conn, "/users/account-setup")

      # Fill required name field, leave password empty
      view
      |> form("#account_setup_form",
        user: %{
          name: "Jane Smith",
          password: "",
          password_confirmation: ""
        },
        terms_accepted: "true"
      )
      |> render_submit()

      # Should redirect to order tracking (not remain on form)
      assert_redirected(view, ~p"/orders/#{order.id}/track?token=#{order.tracking_token}")
      
      # Should persist user name even without password
      user = Accounts.get_user_by_email("ux_test@example.com")
      assert user.name == "Jane Smith"
      assert is_nil(user.hashed_password) # Confirmed no password was set
    end
  
    # Legacy UX tests (updated for new copy) - will fail until implementation
    test "button labels are clear and distinguish flows", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/account-setup")

      # Updated expected copy (will fail until implemented)
      assert html =~ "Complete Setup with Password"    # New copy
      assert html =~ "Complete Setup without Password" # New copy

      # Should not have old language
      refute html =~ "Skip for now"
      refute html =~ "Complete Account Setup"  # Generic old copy
      refute html =~ "Agree and continue without password" # Old copy
    end
  end
end
