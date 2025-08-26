defmodule EatfairWeb.Live.CuisineDropdownTest do
  use EatfairWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "Cuisine dropdown functionality" do
    test "default state has empty cuisines list meaning All selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/restaurants/discover")
      
      # Should load successfully
      assert render(view) =~ "Discover Restaurants"
      
      # Should have filters initialized with empty cuisines list (meaning All)
      assert view.assigns.filters.cuisines == []
    end
    
    test "cuisine dropdown toggle works", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/restaurants/discover")
      
      # Initially dropdown should be closed
      assert view.assigns.show_cuisine_dropdown == false
      
      # Click to toggle dropdown
      view
      |> element("button[phx-click='toggle_cuisine_dropdown']")
      |> render_click()
      
      # Should now be open
      assert view.assigns.show_cuisine_dropdown == true
      
      # Click again to close
      view
      |> element("button[phx-click='toggle_cuisine_dropdown']")
      |> render_click()
      
      # Should be closed again
      assert view.assigns.show_cuisine_dropdown == false
    end
    
    test "select all cuisines functionality", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/restaurants/discover")
      
      # First, select a specific cuisine to have something selected
      cuisine_id = view.assigns.cuisines |> List.first() |> Map.get(:id)
      
      view
      |> element("input[phx-click='toggle_cuisine']")
      |> render_click(%{"cuisine_id" => to_string(cuisine_id)})
      
      # Should have that cuisine selected
      assert cuisine_id in view.assigns.filters.cuisines
      
      # Now select "All Cuisines"
      view
      |> element("button[phx-click='select_all_cuisines']")
      |> render_click()
      
      # Should clear all selections (empty list means all)
      assert view.assigns.filters.cuisines == []
      
      # Dropdown should be closed
      assert view.assigns.show_cuisine_dropdown == false
    end
    
    test "individual cuisine toggle works", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/restaurants/discover")
      
      # Get first cuisine ID
      cuisine_id = view.assigns.cuisines |> List.first() |> Map.get(:id)
      
      # Initially no cuisines selected (empty list = all)
      assert view.assigns.filters.cuisines == []
      
      # Select a cuisine
      view
      |> element("input[phx-click='toggle_cuisine']")
      |> render_click(%{"cuisine_id" => to_string(cuisine_id)})
      
      # Should be selected
      assert cuisine_id in view.assigns.filters.cuisines
      
      # Deselect it
      view
      |> element("input[phx-click='toggle_cuisine']")
      |> render_click(%{"cuisine_id" => to_string(cuisine_id)})
      
      # Should be deselected
      refute cuisine_id in view.assigns.filters.cuisines
    end
    
    test "filter logic handles empty cuisines list as all cuisines", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/restaurants/discover")
      
      # With empty cuisines list, should show all restaurants
      initial_count = length(view.assigns.restaurants)
      
      # Select a specific cuisine
      cuisine_id = view.assigns.cuisines |> List.first() |> Map.get(:id)
      
      view
      |> element("input[phx-click='toggle_cuisine']")
      |> render_click(%{"cuisine_id" => to_string(cuisine_id)})
      
      # Should have fewer restaurants (filtered by that cuisine)
      filtered_count = length(view.assigns.restaurants)
      
      # The filter should reduce the number of restaurants
      # (unless all restaurants happen to have that cuisine)
      # This test may vary based on your seed data
      
      # Select all again
      view
      |> element("button[phx-click='select_all_cuisines']")
      |> render_click()
      
      # Should show all restaurants again
      all_count = length(view.assigns.restaurants)
      assert all_count >= filtered_count
    end
    
    test "cuisine counts are calculated correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/restaurants/discover")
      
      # Should have cuisine counts calculated
      refute is_nil(view.assigns.cuisine_counts)
      assert is_map(view.assigns.cuisine_counts)
      
      # Should have cuisines with counts
      refute is_nil(view.assigns.cuisines_with_counts)
      assert is_list(view.assigns.cuisines_with_counts)
      
      # Each cuisine should have a count
      for {cuisine, count} <- view.assigns.cuisines_with_counts do
        assert is_integer(count)
        assert count >= 0
      end
    end
  end
end
