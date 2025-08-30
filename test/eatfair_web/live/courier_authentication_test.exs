defmodule EatfairWeb.CourierAuthenticationTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures

  describe "🚚 Courier Authentication & Authorization" do
    test "courier can log in and access courier dashboard", %{conn: conn} do
      # 🎯 RED: Write failing test for courier login flow
      courier = user_fixture(%{role: "courier"})

      # Navigate to courier login (should exist)
      {:ok, _login_live, html} = live(conn, "/courier/login")
      assert html =~ "Courier Login"

      # Test that courier can be logged in via test helper and access dashboard
      conn = log_in_user(conn, courier)
      {:ok, _dashboard_live, html} = live(conn, "/courier/dashboard")
      assert html =~ "Available Deliveries"
      assert html =~ "Welcome"
    end

    test "courier cannot access restaurant or admin routes", %{conn: conn} do
      # 🎯 RED: Test authorization boundaries
      courier = user_fixture(%{role: "courier"})
      conn = log_in_user(conn, courier)

      # Should not be able to access restaurant dashboard (requires restaurant ownership)
      conn_restaurant = get(conn, ~p"/restaurant/dashboard")
      assert redirected_to(conn_restaurant) =~ "/restaurant/onboard"
      
      # Should not be able to access admin dashboard (requires admin role)
      conn_admin = get(conn, ~p"/admin/dashboard")
      assert redirected_to(conn_admin) == "/"

      # Should be able to access restaurant onboarding (available to all authenticated users)
      conn_onboard = get(conn, ~p"/restaurant/onboard") 
      assert html_response(conn_onboard, 200)
    end

    test "non-courier users cannot access courier routes", %{conn: conn} do
      # 🎯 RED: Test that restaurant owners/customers can't access courier dashboard
      restaurant_owner = user_fixture(%{role: "restaurant_owner"})
      customer = user_fixture(%{role: "customer"})

      # Restaurant owner should be redirected to courier login when accessing courier dashboard
      conn_restaurant = log_in_user(conn, restaurant_owner)
      conn_restaurant = get(conn_restaurant, ~p"/courier/dashboard")
      assert redirected_to(conn_restaurant) =~ "/courier/login"

      # Customer should be redirected to courier login when accessing courier dashboard
      conn_customer = log_in_user(conn, customer)
      conn_customer = get(conn_customer, ~p"/courier/dashboard") 
      assert redirected_to(conn_customer) =~ "/courier/login"
    end

    test "unauthenticated users are redirected to courier login", %{conn: conn} do
      # 🎯 RED: Test that courier routes require authentication
      conn = get(conn, ~p"/courier/dashboard")
      assert redirected_to(conn) =~ "/courier/login"

      conn = get(conn, ~p"/courier/deliveries/123")
      assert redirected_to(conn) =~ "/courier/login"
    end

    test "courier can logout and is redirected appropriately", %{conn: conn} do
      # 🎯 RED: Test courier logout flow
      courier = user_fixture(%{role: "courier"})
      conn = log_in_user(conn, courier)

      # Courier should be logged in and able to access dashboard
      conn_dashboard = get(conn, ~p"/courier/dashboard")
      assert html_response(conn_dashboard, 200) =~ "Available Deliveries"

      # Logout should redirect to courier login for couriers
      conn_logout = delete(conn, ~p"/users/log-out")
      assert redirected_to(conn_logout) == "/courier/login"

      # After logout, should not be able to access courier dashboard
      conn_after_logout = get(conn_logout, ~p"/courier/dashboard")
      assert redirected_to(conn_after_logout) =~ "/courier/login"
    end

    test "courier navigation shows appropriate menu items", %{conn: conn} do
      # 🎯 RED: Test that courier gets courier-specific navigation
      courier = user_fixture(%{role: "courier"})
      conn = log_in_user(conn, courier)

      {:ok, _dashboard_live, html} = live(conn, "/courier/dashboard")
      
      # Should show courier-specific content
      assert html =~ "Courier Dashboard"
      assert html =~ "Available Deliveries"
      assert html =~ "In Transit"
      assert html =~ "Completed Today"

      # Should not show restaurant or admin navigation
      refute html =~ "Restaurant Dashboard"
      refute html =~ "Menu Management"
      refute html =~ "Admin Panel"
    end
  end
end
