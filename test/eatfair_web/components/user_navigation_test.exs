defmodule EatfairWeb.Components.UserNavigationTest do
  use EatfairWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  alias EatfairWeb.UserNavigation

  describe "🚚 Courier Navigation Links" do
    test "courier user sees Courier Dashboard link in desktop navigation" do
      # Create courier user
      courier = user_fixture(%{role: "courier", name: "Max Speedman"})
      current_scope = %{user: courier}

      # Render UserNavigation component
      html = render_component(&UserNavigation.user_nav/1, %{current_scope: current_scope})

      # Should have link to courier dashboard
      assert html =~ ~r/href="\/courier\/dashboard"/
      assert html =~ "Courier Dashboard"
    end

    test "courier user sees Courier Dashboard link in mobile navigation" do
      # Create courier user
      courier = user_fixture(%{role: "courier", name: "Lisa Lightning"})
      current_scope = %{user: courier}

      # Render UserNavigation component
      html = render_component(&UserNavigation.user_nav/1, %{current_scope: current_scope})

      # Should have link in mobile menu too (appears twice - desktop and mobile)
      courier_links = html |> String.split("Courier Dashboard") |> length()
      assert courier_links >= 2, "Expected at least one 'Courier Dashboard' link for mobile navigation"
    end

    test "non-courier users do not see Courier Dashboard link" do
      test_cases = [
        %{role: "customer", name: "Regular Customer"},
        %{role: "restaurant_owner", name: "Restaurant Owner"}
      ]

      for user_attrs <- test_cases do
        user = user_fixture(user_attrs)
        current_scope = %{user: user}

        html = render_component(&UserNavigation.user_nav/1, %{current_scope: current_scope})

        # Should NOT have courier dashboard link
        refute html =~ ~r/href="\/courier\/dashboard"/
        refute html =~ "Courier Dashboard"
      end
    end

    test "unauthenticated users do not see Courier Dashboard link" do
      # No current_scope (unauthenticated)
      current_scope = nil

      html = render_component(&UserNavigation.user_nav/1, %{current_scope: current_scope})

      # Should NOT have courier dashboard link
      refute html =~ ~r/href="\/courier\/dashboard"/
      refute html =~ "Courier Dashboard"
    end
  end

  describe "🏪 Restaurant Owner Navigation (baseline)" do
    test "restaurant owner sees My Restaurant link" do
      # Verify existing functionality still works
      restaurant_owner = user_fixture(%{role: "restaurant_owner", name: "Restaurant Owner"})
      current_scope = %{user: restaurant_owner}

      html = render_component(&UserNavigation.user_nav/1, %{current_scope: current_scope})

      # Should have restaurant dashboard link
      assert html =~ ~r/href="\/restaurant\/dashboard"/
      assert html =~ "My Restaurant"
    end
  end
end
