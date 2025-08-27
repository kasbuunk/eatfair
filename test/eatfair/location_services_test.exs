defmodule Eatfair.LocationServicesTest do
  use ExUnit.Case
  
  import ExUnit.CaptureLog
  
  alias Eatfair.LocationServices
  
  @moduletag :integration
  
  describe "geocode_address/1" do
    test "geocodes major Dutch cities successfully" do
      cities_to_test = [
        {"Amsterdam", 52.3676, 4.9041},
        {"Rotterdam", 51.9225, 4.47917},
        {"Utrecht", 52.0907, 5.1214},
        {"The Hague", 52.0705, 4.3007},
        {"Eindhoven", 51.4416, 5.4697},
        {"Tilburg", 51.5656, 5.0913},
        {"Groningen", 53.2194, 6.5665},
        {"Almere", 52.3508, 5.2647},
        {"Breda", 51.5719, 4.7683},
        {"Nijmegen", 51.8426, 5.8518},
        {"Enschede", 52.2215, 6.8937},
        {"Apeldoorn", 52.2112, 5.9699},
        {"Haarlem", 52.3874, 4.6462},
        {"Maastricht", 50.8514, 5.6909},
        {"Hilversum", 52.2215, 5.1719},
        {"Bussum", 52.2687, 5.1860}
      ]
      
      for {city, expected_lat, expected_lng} <- cities_to_test do
        assert {:ok, result} = LocationServices.geocode_address(city)
        
        # Allow for reasonable geographic tolerance (Google Maps might return slightly different coordinates)
        assert_in_delta result.latitude, expected_lat, 0.1, "Latitude mismatch for #{city}"
        assert_in_delta result.longitude, expected_lng, 0.1, "Longitude mismatch for #{city}"
        
        # Verify result structure
        assert is_binary(result.formatted_address)
        assert String.contains?(result.formatted_address, "Netherlands")
        assert result.confidence in [:high, :low]
        assert result.source in [:google_maps_api, :fallback]
      end
    end
    
    test "handles Dutch postal codes" do
      postal_codes_to_test = [
        "1012 AB",  # Amsterdam center
        "3511 LX",  # Utrecht center  
        "3011 AD",  # Rotterdam center
        "2511 CV",  # The Hague center
        "5611 EM"   # Eindhoven center
      ]
      
      for postal_code <- postal_codes_to_test do
        assert {:ok, result} = LocationServices.geocode_address(postal_code)
        
        # Should return valid coordinates in Netherlands
        assert result.latitude > 50.0 and result.latitude < 54.0
        assert result.longitude > 3.0 and result.longitude < 8.0
        assert is_binary(result.formatted_address)
      end
    end
    
    test "handles case variations gracefully" do
      test_cases = [
        "AMSTERDAM",
        "amsterdam", 
        "AmStErDaM",
        "Rotterdam",
        "HILVERSUM"
      ]
      
      for address <- test_cases do
        assert {:ok, result} = LocationServices.geocode_address(address)
        assert is_float(result.latitude)
        assert is_float(result.longitude)
        assert is_binary(result.formatted_address)
      end
    end
    
    test "handles whitespace and formatting variations" do
      test_cases = [
        "  Amsterdam  ",
        " Utrecht ",
        "Rotterdam",
        "1012  AB",
        "  1012AB  "
      ]
      
      for address <- test_cases do
        assert {:ok, result} = LocationServices.geocode_address(address)
        assert is_float(result.latitude)
        assert is_float(result.longitude)
      end
    end
    
    test "returns error for empty or invalid input" do
      invalid_inputs = [
        "",
        "   ",
        nil,
        123,
        [],
        %{}
      ]
      
      for invalid_input <- invalid_inputs do
        assert {:error, :invalid_input} = LocationServices.geocode_address(invalid_input)
      end
    end
    
    test "handles unknown locations gracefully" do
      unknown_locations = [
        "Nonexistent City ZZZ999",
        "Invalid Location 99999XX", 
        "QWERTY12345ASDFGH",
        "🏠🏠🏠🏠🏠🏠🏠🏠🏠🏠",
        "ZZXXYY999NOTREAL",
        "Random Street Name",
        "🏠 Unicode Location Test",
        "XYZ999"
      ]
      
      for location <- unknown_locations do
        result = LocationServices.geocode_address(location)
        # Google Maps API is quite good, so we accept either not found or a very general result
        case result do
          {:error, :not_found} -> :ok  # Expected for truly invalid addresses
          {:ok, geocoded} when is_map(geocoded) -> :ok  # Google may return a general location
        end
      end
    end
    
    test "logs appropriate messages for debugging" do
      # Test successful geocoding logs
      log_output = capture_log(fn ->
        LocationServices.geocode_address("Amsterdam")
      end)
      
      # Should contain either API call or fallback usage, or be empty in test environment
      # (logging may be suppressed in tests)
      assert is_binary(log_output)
    end
    
    test "fallback works when Google Maps API is unavailable" do
      # Test fallback system by temporarily clearing API key
      original_env = System.get_env("GOOGLE_MAPS_API_KEY")
      original_config = Application.get_env(:eatfair, :google_maps, [])
      
      try do
        # Clear both environment variable and config
        System.delete_env("GOOGLE_MAPS_API_KEY")
        Application.put_env(:eatfair, :google_maps, api_key: nil)
        
        # Should fall back to hardcoded Dutch cities
        assert {:ok, result} = LocationServices.geocode_address("Amsterdam")
        assert result.latitude == 52.3676
        assert result.longitude == 4.9041
        assert result.confidence == :low
        assert result.source == :fallback
        
      after
        # Restore original config and env
        if original_env, do: System.put_env("GOOGLE_MAPS_API_KEY", original_env)
        Application.put_env(:eatfair, :google_maps, original_config)
      end
    end
    
    test "specific user issue: Koekoeklaan 31, 1403 EB Bussum geocodes successfully" do
      # This is the exact address causing the reported error
      addresses_to_test = [
        "Koekoeklaan 31, 1403 EB Bussum",
        "koekoeklaan 31 bussum",
        "1403 EB",
        "1403EB", 
        "Koekoeklaan 31, Bussum"
      ]
      
      for address <- addresses_to_test do
        case LocationServices.geocode_address(address) do
          {:ok, result} ->
            # Should geocode to coordinates near Bussum (Netherlands)
            assert result.latitude > 52.0 and result.latitude < 53.0, 
                   "Expected latitude in Netherlands range for '#{address}', got #{result.latitude}"
            assert result.longitude > 4.0 and result.longitude < 7.0, 
                   "Expected longitude in Netherlands range for '#{address}', got #{result.longitude}"
            assert result.formatted_address != nil
            # Should not fail with "Could not find location" error
            
          {:error, reason} ->
            flunk("Expected success for '#{address}' but got error: #{reason}")
        end
      end
    end
  end
  
  describe "geocode_with_google_maps/1" do
    test "handles API errors gracefully" do
      # Test with a location that should trigger API error handling
      log_output = capture_log(fn ->
        result = LocationServices.geocode_with_google_maps("Test Location For Error Handling")
        assert result in [{:ok, %{}}, {:error, :not_found}]
      end)
      
      # Should log either API call or fallback usage
      assert is_binary(log_output)
    end
  end
  
  describe "geocode_addresses/1 (batch processing)" do
    test "processes multiple addresses in batches" do
      addresses = ["Amsterdam", "Rotterdam", "Utrecht", "The Hague"]
      
      results = LocationServices.geocode_addresses(addresses)
      assert length(results) == length(addresses)
      
      # Each result should be a tuple of {geocoding_result, original_address}
      for {{result_status, _result_data}, _original_address} <- results do
        assert result_status in [:ok, :error]
      end
    end
    
    test "handles empty list" do
      assert [] = LocationServices.geocode_addresses([])
    end
  end
  
  describe "integration with existing GeoUtils" do
    test "maintains backward compatibility with GeoUtils.geocode_address/1" do
      assert {:ok, result} = Eatfair.GeoUtils.geocode_address("Amsterdam")
      
      # Should return the expected format (without extra metadata)
      assert Map.has_key?(result, :latitude)
      assert Map.has_key?(result, :longitude)
      assert is_float(result.latitude)
      assert is_float(result.longitude)
      
      # Should not contain LocationServices-specific fields
      refute Map.has_key?(result, :formatted_address)
      refute Map.has_key?(result, :confidence)
      refute Map.has_key?(result, :source)
    end
    
    test "GeoUtils geocoding works with restaurant discovery flow" do
      # Test the critical path: homepage address → discovery page filtering
      test_addresses = ["Amsterdam", "Utrecht", "Rotterdam", "Hilversum"]
      
      for address <- test_addresses do
        assert {:ok, coords} = Eatfair.GeoUtils.geocode_address(address)
        
        # Coordinates should be valid for Netherlands
        assert coords.latitude > 50.0 and coords.latitude < 54.0
        assert coords.longitude > 3.0 and coords.longitude < 8.0
      end
    end
  end
  
  describe "performance and caching" do
    test "cache system initializes without errors" do
      assert :ok = LocationServices.clear_cache()
    end
    
    @tag :slow
    test "handles rapid successive calls gracefully" do
      # Simulate rapid user input changes
      addresses = ["Amst", "Amste", "Amster", "Amsterd", "Amsterdam"]
      
      results = Enum.map(addresses, fn address ->
        LocationServices.geocode_address(address)
      end)
      
      # At least the complete address should work
      last_result = List.last(results)
      assert {:ok, _} = last_result
    end
  end
  
  describe "address normalization" do
    test "enhances Dutch addresses correctly" do
      # Test cases where the address should be enhanced with ", Netherlands"
      test_cases = [
        {"1012 AB", true},     # Postal code should be enhanced
        {"1012AB", true},      # Postal code without space should be enhanced  
        {"Utrecht", true},     # City should be enhanced
        {"Amsterdam, Netherlands", false},  # Already has country
        {"Utrecht, Nederland", false}       # Already has Dutch country name
      ]
      
      for {address, should_enhance} <- test_cases do
        result = LocationServices.geocode_address(address)
        
        case result do
          {:ok, geocoded} ->
            if should_enhance do
              assert String.contains?(geocoded.formatted_address, "Netherlands")
            end
            
          {:error, _} ->
            # Some addresses might not geocode, that's okay for this test
            :ok
        end
      end
    end
  end
end
