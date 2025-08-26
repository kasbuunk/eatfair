defmodule Eatfair.LocationInferenceTest do
  use Eatfair.DataCase

  alias Eatfair.LocationInference
  alias Eatfair.AccountsFixtures
  alias Eatfair.Accounts

  describe "infer_location/1" do
    test "returns high confidence with user saved address when user is authenticated with address" do
      user = AccountsFixtures.user_fixture()
      {:ok, _address} = Accounts.create_address(%{
        "user_id" => user.id,
        "name" => "Home",
        "street_address" => "Damrak 1",
        "city" => "Amsterdam",
        "postal_code" => "1012JS",
        "is_default" => true
      })
      
      socket = %{assigns: %{current_scope: %{user: user}}}
      
      result = LocationInference.infer_location(socket)
      
      assert result.confidence == :high
      assert result.source == :user_profile
      assert result.address == "Damrak 1, Amsterdam, 1012JS"
    end

    test "returns high confidence with first address when user has multiple addresses but no default" do
      user = AccountsFixtures.user_fixture()
      
      # Create multiple addresses, none marked as default
      {:ok, _address1} = Accounts.create_address(%{
        "user_id" => user.id,
        "name" => "Home",
        "street_address" => "Prinsengracht 100",
        "city" => "Amsterdam",
        "postal_code" => "1015DZ",
        "is_default" => false
      })
      
      {:ok, _address2} = Accounts.create_address(%{
        "user_id" => user.id,
        "name" => "Work",
        "street_address" => "Herengracht 200",
        "city" => "Amsterdam",
        "postal_code" => "1016BS",
        "is_default" => false
      })
      
      socket = %{assigns: %{current_scope: %{user: user}}}
      
      result = LocationInference.infer_location(socket)
      
      assert result.confidence == :high
      assert result.source == :user_profile
      # Should use first address since no default
      assert result.address == "Prinsengracht 100, Amsterdam, 1015DZ"
    end

    test "returns medium confidence with session address when user has no saved addresses" do
      user = AccountsFixtures.user_fixture()
      socket = %{assigns: %{current_scope: %{user: user}, session_location: "Utrecht, Netherlands"}}
      
      result = LocationInference.infer_location(socket)
      
      assert result.confidence == :medium
      assert result.source == :session_data
      assert result.address == "Utrecht, Netherlands"
    end

    test "returns low confidence with empty address when no location data available" do
      socket = %{assigns: %{}}
      
      result = LocationInference.infer_location(socket)
      
      assert result.confidence == :low
      assert result.source == :none
      assert result.address == ""
    end

    test "prioritizes user address over session data" do
      user = AccountsFixtures.user_fixture()
      {:ok, _address} = Accounts.create_address(%{
        "user_id" => user.id,
        "name" => "Home",
        "street_address" => "Nieuwmarkt 10",
        "city" => "Amsterdam",
        "postal_code" => "1011HP",
        "is_default" => true
      })
      
      socket = %{assigns: %{current_scope: %{user: user}, session_location: "Utrecht, Netherlands"}}
      
      result = LocationInference.infer_location(socket)
      
      assert result.confidence == :high
      assert result.source == :user_profile
      assert result.address == "Nieuwmarkt 10, Amsterdam, 1011HP"
    end
  end

  describe "format_address/1" do
    test "formats complete address with all fields" do
      address = %{
        street_address: "Damrak 1",
        city: "Amsterdam", 
        postal_code: "1012JS"
      }
      
      result = LocationInference.format_address(address)
      assert result == "Damrak 1, Amsterdam, 1012JS"
    end

    test "handles missing fields gracefully" do
      address = %{
        street_address: "Prinsengracht 100",
        city: "Amsterdam",
        postal_code: ""
      }
      
      result = LocationInference.format_address(address)
      assert result == "Prinsengracht 100, Amsterdam"
    end

    test "returns city and postal code when street address is missing" do
      address = %{
        street_address: nil,
        city: "Amsterdam",
        postal_code: "1012JS"
      }
      
      result = LocationInference.format_address(address)
      assert result == "Amsterdam, 1012JS"
    end

    test "returns empty string when all fields are empty" do
      address = %{
        street_address: nil,
        city: "  ",
        postal_code: nil
      }
      
      result = LocationInference.format_address(address)
      assert result == ""
    end
  end

  describe "session location management" do
    test "stores and retrieves session location" do
      socket = %{assigns: %{}}
      address = "Amsterdam, Netherlands"
      
      updated_socket = LocationInference.store_session_location(socket, address)
      result = LocationInference.get_session_location(updated_socket)
      
      assert result == address
    end

    test "returns nil when no session location is stored" do
      socket = %{assigns: %{}}
      
      result = LocationInference.get_session_location(socket)
      assert result == nil
    end
  end

  describe "geolocation request management" do
    test "should_request_geolocation? returns true when not yet requested" do
      socket = %{assigns: %{}}
      
      assert LocationInference.should_request_geolocation?(socket) == true
    end

    test "should_request_geolocation? returns false when already requested" do
      socket = %{assigns: %{geolocation_requested: true}}
      
      assert LocationInference.should_request_geolocation?(socket) == false
    end

    test "mark_geolocation_requested updates the socket" do
      socket = %{assigns: %{}}
      
      updated_socket = LocationInference.mark_geolocation_requested(socket)
      
      assert LocationInference.should_request_geolocation?(updated_socket) == false
    end
  end
end
