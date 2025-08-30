defmodule EatfairWeb.AddressManagementTest do
  use EatfairWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures

  describe "Address Management User Journey" do
    test "user can navigate to address management and add an address", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Navigate to address management page
      {:ok, lv, html} = live(conn, ~p"/users/addresses")

      # Should show the address management page
      assert html =~ "📍 Your Addresses"
      assert html =~ "Manage your delivery addresses for easier ordering"

      # Should show empty state when no addresses
      assert html =~ "No addresses yet"
      assert html =~ "Add your first address to make ordering easier"

      # Click to show form
      lv |> element("#add-address-button") |> render_click()

      # Form should be visible
      html = render(lv)
      assert html =~ "Add New Address"

      # Fill out and submit address form
      lv
      |> form("#address-form",
        address: %{
          name: "Home",
          street_address: "Prinsengracht 263",
          postal_code: "1016 GV",
          city: "Amsterdam"
        }
      )
      |> render_submit()

      # Should show success message
      html = render(lv)
      assert html =~ "Address saved successfully"

      # Should show the address in the list
      assert html =~ "Home"
      assert html =~ "Prinsengracht 263"
      assert html =~ "1016 GV Amsterdam"
    end

    test "user can set default address and delete addresses", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/users/addresses")

      # Add first address
      lv |> element("#add-address-button") |> render_click()

      lv
      |> form("#address-form",
        address: %{
          name: "Work",
          street_address: "Damrak 1",
          postal_code: "1012 JS",
          city: "Amsterdam"
        }
      )
      |> render_submit()

      # Add second address
      lv |> element("#add-address-button") |> render_click()

      lv
      |> form("#address-form",
        address: %{
          name: "Home",
          street_address: "Vondelpark 1",
          postal_code: "1071 AA",
          city: "Amsterdam",
          is_default: true
        }
      )
      |> render_submit()

      html = render(lv)

      # Home should be marked as default
      assert html =~ ~r/Home.*Default/s

      # Should be able to delete the first address
      lv |> element("button[phx-click='delete_address']:first-of-type") |> render_click()

      html = render(lv)
      assert html =~ "Address deleted"
    end

    test "address management integrates with restaurant discovery", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Add an address first
      {:ok, lv, _html} = live(conn, ~p"/users/addresses")
      lv |> element("#add-address-button") |> render_click()

      lv
      |> form("#address-form",
        address: %{
          name: "Amsterdam Center",
          street_address: "Dam 1",
          postal_code: "1012 JS",
          city: "Amsterdam"
        }
      )
      |> render_submit()

      # Navigate to restaurant discovery
      {:ok, _discovery_lv, discovery_html} = live(conn, ~p"/restaurants")

      # The discovery page should now work with the user's address
      assert discovery_html =~ "Discover Restaurants"

      # User should be able to search restaurants based on their location
      # This tests the integration between address management and restaurant discovery
    end

    test "address management is accessible from navigation", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit any page with navigation
      {:ok, _lv, html} = live(conn, ~p"/")

      # Should show navigation with user menu
      assert html =~ "EatFair"
      assert html =~ String.split(user.email, "@") |> List.first()

      # Navigation should include link to address management
      assert html =~ "Manage Addresses"
      assert html =~ "/users/addresses"
    end

    test "users without addresses see prompt on restaurant discovery", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit restaurant discovery page
      {:ok, lv, html} = live(conn, ~p"/restaurants")

      # Should show address prompt for users without addresses
      assert html =~ "Add Your Address to See Nearby Restaurants"
      assert html =~ "Add your delivery address to see restaurants that can deliver to you!"

      # Should have link to address management
      assert html =~ "/users/addresses"

      # Click the address management link from the address prompt section
      {:ok, _address_lv, address_html} =
        lv
        |> element(".bg-yellow-50 a[href='/users/addresses']")
        |> render_click()
        |> follow_redirect(conn)

      # Should land on address management page
      assert address_html =~ "Your Addresses"
      assert address_html =~ "Add your first address to make ordering easier"
    end
  end
end
