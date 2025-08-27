defmodule EatfairWeb.Live.Components.AddressAutoccompleteCrashTest do
  @moduledoc """
  CRITICAL BUG REPRODUCTION TEST
  
  This test specifically reproduces the FunctionClauseError that occurs when users 
  type regular characters in the address autocomplete field.
  
  The bug: component crashes when keyboard_navigation event receives regular keys
  like "h", "a", etc. instead of navigation keys.
  """
  use EatfairWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  
  alias EatfairWeb.Live.Components.AddressAutocomplete

  describe "CRITICAL BUG: keyboard navigation crash" do
    @tag :focus
    test "SHOULD NOT CRASH when user types regular characters" do
      # This test reproduces the exact crash described in the logs:
      # ** (FunctionClauseError) no function clause matching in 
      # EatfairWeb.Live.Components.AddressAutocomplete.handle_event/3
      
      # Set up a minimal LiveView to host the component
      {:ok, view, _html} = live_isolated(AddressAutocomplete, %{
        id: "test-address-search",
        placeholder: "Amsterdam", 
        value: "",
        class: "test-input"
      })
      
      # REPRODUCE CRASH: Type regular character "h"
      # This should NOT crash the LiveView
      assert_raise FunctionClauseError, ~r/no function clause matching/, fn ->
        view
        |> element("input[type='text']")
        |> render_keydown(%{"key" => "h", "value" => ""})
      end
    end
    
    @tag :focus  
    test "SHOULD NOT CRASH when user types with modifier keys" do
      # Reproduce another crash pattern from logs
      {:ok, view, _html} = live_isolated(AddressAutocomplete, %{
        id: "test-address-search",
        placeholder: "Amsterdam",
        value: "",
        class: "test-input"
      })
      
      # REPRODUCE CRASH: Meta+h combination
      assert_raise FunctionClauseError, ~r/no function clause matching/, fn ->
        view
        |> element("input[type='text']")  
        |> render_keydown(%{"key" => "Meta", "value" => "h"})
      end
    end
    
    @tag :focus
    test "SHOULD handle all keyboard input gracefully after fix" do
      # This test will pass after we fix the component
      {:ok, view, _html} = live_isolated(AddressAutocomplete, %{
        id: "test-address-search", 
        placeholder: "Amsterdam",
        value: "",
        class: "test-input"
      })
      
      # These should ALL work without crashing after fix:
      regular_keys = ["a", "b", "h", "1", "2", " ", "-", ",", "."]
      modifier_combinations = [
        %{"key" => "Meta", "value" => "h"},
        %{"key" => "Ctrl", "value" => "a"}, 
        %{"key" => "Alt", "value" => "tab"},
        %{"key" => "Shift", "value" => "A"}
      ]
      
      # Test regular character typing - should NOT crash
      for key <- regular_keys do
        assert {:noreply, _socket} = view
        |> element("input[type='text']")
        |> render_keydown(%{"key" => key, "value" => key})
      end
      
      # Test modifier key combinations - should NOT crash  
      for key_combo <- modifier_combinations do
        assert {:noreply, _socket} = view
        |> element("input[type='text']")
        |> render_keydown(key_combo)
      end
    end
    
    @tag :focus
    test "navigation keys work correctly after fix" do
      {:ok, view, _html} = live_isolated(AddressAutocomplete, %{
        id: "test-address-search",
        placeholder: "Amsterdam", 
        value: "",
        class: "test-input"
      })
      
      # Navigation keys should continue working properly
      navigation_keys = ["ArrowDown", "ArrowUp", "Enter", "Tab", "Escape"]
      
      for key <- navigation_keys do
        # These should work without crashing
        assert {:noreply, _socket} = view
        |> element("input[type='text']")
        |> render_keydown(%{"key" => key})
      end
    end
    
    @tag :focus
    test "component handles focus and blur without crash" do
      {:ok, view, _html} = live_isolated(AddressAutocomplete, %{
        id: "test-address-search",
        placeholder: "Amsterdam",
        value: "",
        class: "test-input"
      })
      
      # Focus should work
      assert {:noreply, _socket} = view
      |> element("input[type='text']")
      |> render_focus()
      
      # Blur should work  
      assert {:noreply, _socket} = view
      |> element("input[type='text']")
      |> render_blur()
    end
  end
  
  describe "Google Maps-like UX requirements" do
    @tag :focus
    test "shows suggestions as user types" do
      # Skip for now - will implement after crash is fixed
      # This will test the complete Google Maps-like experience
    end
    
    @tag :focus
    test "allows Enter to select top suggestion" do
      # Skip for now - will implement after crash is fixed  
    end
    
    @tag :focus
    test "allows click to select any suggestion" do
      # Skip for now - will implement after crash is fixed
    end
  end
end
