defmodule EatfairWeb.UniversalNavbarTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures

  describe "navbar presence across pages" do
    setup do
      %{user: user_fixture()}
    end

    test "navbar appears on user dashboard", %{conn: conn, user: user} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/dashboard")

      # Check for navbar elements
      assert html =~ "Navigation bar"
      # Brand name
      assert html =~ "Eatfair"
      assert html =~ "Discover Restaurants"
      assert html =~ "Dashboard"
      assert html =~ "Track Orders"
    end

    test "navbar appears on addresses page", %{conn: conn, user: user} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/addresses")

      # Check for navbar elements
      assert html =~ "Navigation bar"
      # Brand name
      assert html =~ "Eatfair"
      assert html =~ "Discover Restaurants"
      assert html =~ "Dashboard"
      assert html =~ "Track Orders"
    end

    test "navbar appears on order tracking page", %{conn: conn, user: user} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/orders/track")

      # Check for navbar elements
      assert html =~ "Navigation bar"
      # Brand name
      assert html =~ "Eatfair"
      assert html =~ "Discover Restaurants"
      assert html =~ "Dashboard"
      assert html =~ "Track Orders"
    end

    test "navbar appears on restaurant discovery page", %{conn: conn, user: user} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/restaurants")

      # Check for navbar elements
      assert html =~ "Navigation bar"
      # Brand name
      assert html =~ "Eatfair"
      assert html =~ "Discover Restaurants"
      assert html =~ "Dashboard"
      assert html =~ "Track Orders"
    end

    test "navbar appears for unauthenticated users on public pages", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/restaurants")

      # Check for navbar elements (unauthenticated version)
      assert html =~ "Navigation bar"
      # Brand name
      assert html =~ "Eatfair"
      assert html =~ "Discover Restaurants"
      assert html =~ "Log In"
      assert html =~ "Sign Up"
    end

    test "theme toggle appears in navbar", %{conn: conn, user: user} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/dashboard")

      # Check for theme toggle elements
      assert html =~ "System theme"
      assert html =~ "Light theme"
      assert html =~ "Dark theme"
    end
  end
end
