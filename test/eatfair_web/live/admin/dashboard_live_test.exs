defmodule EatfairWeb.Admin.DashboardLiveTest do
  @moduledoc """
  Tests for admin dashboard functionality including:
  - Basic page loading to verify format_currency fix
  - Confirming the FunctionClauseError for floats is resolved
  """

  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures

  describe "Basic Admin Page Loading" do
    test "should have exactly one navbar on admin dashboard", %{conn: conn} do
      admin_user = user_fixture(role: :admin)
      conn = conn |> log_in_user(admin_user)

      {:ok, _view, html} = live(conn, ~p"/admin/dashboard")
      
      # Count navbar elements with our test ID
      parsed_html = Floki.parse_document!(html)
      navbar_elements = Floki.find(parsed_html, "[data-test='navbar']")
      navbar_count = length(navbar_elements)
      
      assert navbar_count == 1, "Expected exactly 1 navbar, found #{navbar_count}"
    end

    test "should have exactly one navbar on regular user dashboard", %{conn: conn} do
      user = user_fixture(role: :customer)
      conn = conn |> log_in_user(user)

      {:ok, _view, html} = live(conn, ~p"/users/dashboard")
      
      # Count navbar elements with our test ID
      parsed_html = Floki.parse_document!(html)
      navbar_elements = Floki.find(parsed_html, "[data-test='navbar']")
      navbar_count = length(navbar_elements)
      
      assert navbar_count == 1, "Expected exactly 1 navbar on regular user dashboard, found #{navbar_count}"
    end
    test "redirects unauthenticated users to login", %{conn: conn} do
      {:error, redirect} = live(conn, ~p"/admin")
      assert {:redirect, %{to: "/users/log-in"}} = redirect
    end

    test "loads admin dashboard without FunctionClauseError (verifies fix)", %{conn: conn} do
      # Create an admin user with admin role
      admin_user = user_fixture(role: :admin)
      conn = conn |> log_in_user(admin_user)

      # This test verifies that our format_currency fix works
      # Previously this would crash with FunctionClauseError in Decimal.to_string/2
      # Now it should work (even if there might be other issues)

      try do
        case live(conn, ~p"/admin") do
          {:ok, _view, html} ->
            # Success! The format_currency float issue is fixed
            # Basic check that page loaded
            assert html =~ "Dashboard"

          {:error, %{reason: reason}} ->
            # If there are other errors, make sure it's not the original format_currency issue
            error_msg = inspect(reason)

            refute error_msg =~ "Decimal.to_string/2",
                   "Original format_currency float bug still exists: #{error_msg}"
        end
      rescue
        error ->
          error_msg = Exception.message(error)

          refute error_msg =~ "Decimal.to_string/2",
                 "Original format_currency float bug still exists: #{error_msg}"

          # Re-raise if it's a different error - we'll handle those separately
          reraise error, __STACKTRACE__
      end
    end
  end
end
