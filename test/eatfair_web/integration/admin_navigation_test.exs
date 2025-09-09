defmodule EatfairWeb.Integration.AdminNavigationTest do
  @moduledoc """
  Integration test for admin dashboard navigation feature.
  Validates complete user flow: homepage → admin dashboard navigation.
  """

  use EatfairWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures

  describe "Admin Dashboard Navigation Integration" do
    test "admin user can navigate from homepage to admin dashboard", %{conn: conn} do
      # Create admin user
      admin = user_fixture(%{role: "admin", name: "Test Admin"})
      conn = log_in_user(conn, admin)

      # Start at homepage
      {:ok, homepage, html} = live(conn, "/")

      # Verify admin dashboard link is present with testid
      assert html =~ ~r/data-testid="admin-dashboard-link"/
      assert html =~ "Admin Dashboard"
      assert has_element?(homepage, "[data-testid='admin-dashboard-link']")

      # Click the admin dashboard link (simulate navigation - desktop version)
      admin_link = element(homepage, ".hidden.md\\:flex [data-testid='admin-dashboard-link']")
      render_click(admin_link)

      # Should navigate to admin dashboard
      assert_redirected(homepage, "/admin/dashboard")
    end

    test "non-admin user cannot see admin dashboard link on homepage", %{conn: conn} do
      # Test with different non-admin roles
      test_roles = ["customer", "restaurant_owner", "courier"]

      for role <- test_roles do
        user = user_fixture(%{role: role, name: "Non-Admin User"})
        conn = log_in_user(conn, user)

        {:ok, _homepage, html} = live(conn, "/")

        # Should NOT have admin dashboard link or testid
        refute html =~ ~r/data-testid="admin-dashboard-link"/
        refute html =~ "Admin Dashboard"
      end
    end

    test "unauthenticated user cannot see admin dashboard link on homepage", %{conn: conn} do
      # Visit homepage without authentication
      {:ok, _homepage, html} = live(conn, "/")

      # Should NOT have admin dashboard link or testid
      refute html =~ ~r/data-testid="admin-dashboard-link"/
      refute html =~ "Admin Dashboard"
    end
  end
end
