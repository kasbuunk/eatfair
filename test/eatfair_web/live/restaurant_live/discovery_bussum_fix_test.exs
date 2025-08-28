defmodule EatfairWeb.RestaurantLive.DiscoveryBussumFixTest do
  use EatfairWeb.ConnCase
  
  import Phoenix.LiveViewTest
  import Eatfair.RestaurantsFixtures
  
  describe "Discovery LiveView - Bussum address fix" do
    test "handles Bussum addresses without showing 'Could not find location' error", %{conn: conn} do
      # Create some test restaurants for the test
      _restaurant1 = restaurant_fixture(%{
        name: "Amsterdam Central Pizza",
        latitude: Decimal.new("52.3791"),
        longitude: Decimal.new("4.9003"),
        delivery_radius_km: 5,
        is_open: true
      })
      
      _restaurant2 = restaurant_fixture(%{
        name: "Hilversum Healthy",
        latitude: Decimal.new("52.2279"),
        longitude: Decimal.new("5.1693"),
        delivery_radius_km: 15, # Large radius to include Bussum
        is_open: true
      })
      
      # Test addresses that should work (the user's reported issue)
      test_addresses = [
        "Koekoeklaan 31, 1403 EB Bussum",
        "koekoeklaan 31 bussum", 
        "Bussum",
        "1403 EB"
      ]
      
      for address <- test_addresses do
        # Navigate to discovery page with the address
        {:ok, lv, html} = live(conn, "/restaurants?location=#{URI.encode(address)}")
        
        # Should not contain the error "Could not find location"
        refute html =~ "Could not find location"
        
        # Should contain either success message or show restaurants
        success_indicators = [
          "restaurants delivering to",
          "Found",
          "restaurants found"
        ]
        
        has_success_indicator = Enum.any?(success_indicators, fn indicator ->
          html =~ indicator
        end)
        
        # Should either have success indicator or show restaurants (not error)
        assert has_success_indicator or length(lv |> element("div[data-testid='restaurant-card']") |> has_element?()) > 0,
               "Expected success for address '#{address}' but got error page"
        
        # Verify the page loads without crashes
        assert html =~ "Discover Restaurants"
      end
    end
    
    test "shows helpful message when no restaurants deliver to location", %{conn: conn} do
      # Create restaurant that's too far from Bussum
      _restaurant = restaurant_fixture(%{
        name: "Far Away Restaurant",  
        latitude: Decimal.new("51.5074"), # London coordinates
        longitude: Decimal.new("-0.1278"),
        delivery_radius_km: 5, # Small radius, won't reach Bussum
        is_open: true
      })
      
      address = "Bussum"
      
      {:ok, _lv, html} = live(conn, "/restaurants?location=#{URI.encode(address)}")
      
      # Should show helpful message, not error
      assert html =~ "No restaurants found that deliver to" or 
             html =~ "Showing all restaurants" or
             html =~ "restaurants delivering to"
      
      # Should NOT show the confusing error message
      refute html =~ "Could not find location"
    end
    
    test "geocoding works for various Bussum address formats" do
      # Test that the underlying geocoding works for different formats using Google Maps API
      test_cases = [
        "Bussum",
        "1403 EB", 
        "1403EB",
        "Koekoeklaan 31, Bussum",
        "Koekoeklaan 31, 1403 EB Bussum"
      ]
      
      for address <- test_cases do
        case Eatfair.GeoUtils.geocode_address(address) do
          {:ok, result} ->
            # Should return valid Netherlands coordinates via Google Maps API
            assert result.latitude > 52.0 and result.latitude < 53.0
            assert result.longitude > 4.0 and result.longitude < 7.0
            
          {:error, reason} ->
            flunk("Expected geocoding to work for '#{address}' via Google Maps API, got error: #{reason}")
        end
      end
    end
    
    test "location parameter properly formats addresses", %{conn: conn} do
      # Test that URL parameters are handled correctly
      address_with_spaces = "Koekoeklaan 31, 1403 EB Bussum"
      encoded_address = URI.encode(address_with_spaces)
      
      {:ok, lv, _html} = live(conn, "/restaurants?location=#{encoded_address}")
      
      # Check that the location is properly stored in the socket
      location = :sys.get_state(lv.pid).socket.assigns.location
      assert location != nil
      assert String.contains?(String.downcase(location), "bussum")
    end
  end
end
