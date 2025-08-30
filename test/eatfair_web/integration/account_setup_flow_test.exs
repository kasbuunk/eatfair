defmodule EatfairWeb.AccountSetupFlowTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
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
        user: %{password: "", password_confirmation: ""},
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

  describe "🎨 Account Setup UX Flow" do
    setup %{conn: conn} do
      user = user_fixture(%{confirmed_at: DateTime.utc_now()})
      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "terms checkbox is not required for skip path", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/account-setup")

      # Terms checkbox should not be required
      refute html =~ ~r/required.*terms_accepted/

      # Should have clear messaging about implicit agreement
      assert html =~ "By continuing you agree to the"
    end

    test "button labels are clear and intuitive", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/users/account-setup")

      # Should have the improved button copy
      assert html =~ "Complete Account Setup"
      assert html =~ "Agree and continue without password"

      # Should not have passive language
      refute html =~ "Skip for now"
    end

    test "save path still requires terms acceptance when checkbox is checked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/users/account-setup")

      # Try to submit without terms acceptance (omit terms_accepted to leave unchecked)
      result =
        view
        |> form("#account_setup_form",
          user: %{password: "password123", password_confirmation: "password123"}
        )
        |> render_submit()

      # Should either show error OR stay on the same page (not redirect)
      # For now, just verify we don't get redirected to track page
      refute result =~ "phx-trigger-action"
      # The form should still be present (not redirected)
      assert render(view) =~ "Complete Account Setup"
    end
  end
end
