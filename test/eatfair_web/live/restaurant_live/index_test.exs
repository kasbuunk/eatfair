defmodule EatfairWeb.RestaurantLive.IndexTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  alias Eatfair.Accounts

  describe "Homepage" do
    test "displays three user paths", %{conn: conn} do
      {:ok, lv, html} = live(conn, "/")

      # Check for main heading
      assert html =~ "Discover Great Food Near You"

      # Check for three user paths
      assert html =~ "Restaurant Owner"
      assert html =~ "Set up your restaurant in less than 3 minutes"
      assert html =~ "Become a Courier"
      assert html =~ "Start Delivering"
      assert html =~ "Community First"
      assert html =~ "Supporting local entrepreneurs"

      # Check for location input
      assert has_element?(lv, "input[name='location']")
      assert has_element?(lv, "button[type='submit']", "Find Restaurants")
    end

    test "location input shows empty value with fallback placeholder", %{conn: conn} do
      {:ok, lv, html} = live(conn, "/")

      # Debug: Print HTML to see what's rendered
      # IO.puts("HTML: #{html}")

      # Should show empty location input with fallback placeholder for anonymous users
      assert has_element?(lv, "input[name='location'][value='']")
      # Check if placeholder contains 'Amsterdam' anywhere in the component
      assert html =~ "Amsterdam"
      refute has_element?(lv, "p", "Using your saved address")
    end

    test "location input uses saved address as smart placeholder", %{conn: conn} do
      user = user_fixture()

      {:ok, _address} =
        Accounts.create_address(%{
          "user_id" => user.id,
          "name" => "Home",
          "street_address" => "Damrak 1",
          "city" => "Amsterdam",
          "postal_code" => "1012JS",
          "is_default" => true
        })

      conn = log_in_user(conn, user)
      {:ok, lv, html} = live(conn, "/")

      # Should show empty value but use saved address as smart placeholder
      assert has_element?(lv, "input[name='location'][value='']")
      # Check that the saved address appears as placeholder text somewhere in the HTML
      assert html =~ "Damrak 1, Amsterdam, 1012JS"
      # This indicator should be removed for placeholder approach
      refute has_element?(lv, "p", "Using your saved address")
    end

    test "location input uses first address as placeholder when user has multiple", %{conn: conn} do
      user = user_fixture()
      # Create first address (not default)
      {:ok, _address1} =
        Accounts.create_address(%{
          "user_id" => user.id,
          "name" => "Home",
          "street_address" => "Prinsengracht 100",
          "city" => "Amsterdam",
          "postal_code" => "1015DZ",
          "is_default" => false
        })

      # Create second address (not default)
      {:ok, _address2} =
        Accounts.create_address(%{
          "user_id" => user.id,
          "name" => "Work",
          "street_address" => "Herengracht 200",
          "city" => "Amsterdam",
          "postal_code" => "1016BS",
          "is_default" => false
        })

      conn = log_in_user(conn, user)
      {:ok, lv, html} = live(conn, "/")

      # Should use first address as placeholder, not as pre-filled value
      assert has_element?(lv, "input[name='location'][value='']")
      # Check that first address appears as placeholder in the HTML
      assert html =~ "Prinsengracht 100, Amsterdam, 1015DZ"
      # Remove confidence indicator for placeholder approach
      refute has_element?(lv, "p", "Using your saved address")
    end

    test "restaurant owner CTA links to onboarding for authenticated users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, "/")

      # Should link directly to restaurant onboarding
      assert has_element?(lv, "a[href='/restaurant/onboard']", "Set up your restaurant")
    end

    test "restaurant owner CTA links to registration for anonymous users", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/")

      # Should link to user registration first  
      assert has_element?(lv, "a[href='/users/register']", "Set up your restaurant")
    end

    test "discover restaurants form navigates to discovery page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, "/")

      # Submit form with fallback location (since no location is entered, it uses fallback)
      lv
      |> form("#discover-form", %{location: ""})
      |> render_submit()

      # Should redirect to discovery page with fallback location parameter
      assert_redirected(lv, "/restaurants?location=Amsterdam")
    end

    test "location input updates reactively as user types", %{conn: conn} do
      {:ok, lv, html} = live(conn, "/")

      # Should have location input with fallback placeholder
      # Fallback placeholder should be visible
      assert html =~ "Amsterdam"

      # Simulate user updating the location first (this would happen via the AddressAutocomplete component)
      send(lv.pid, {"location_selected", "Utrecht"})

      # Now form submission should work with the updated location
      lv
      |> form("#discover-form", %{location: "Utrecht"})
      |> render_submit()

      assert_redirected(lv, "/restaurants?location=Utrecht")
    end
  end
end
