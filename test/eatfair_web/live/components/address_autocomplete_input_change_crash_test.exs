defmodule EatfairWeb.Live.Components.AddressAutocompleteInputChangeCrashTest do
  use EatfairWeb.ConnCase, async: true

  alias EatfairWeb.Live.Components.AddressAutocomplete

  describe "CRITICAL BUG: input_change event crashes" do
    test "FIXED: input_change with _target parameter now handles gracefully" do
      # This was the EXACT error from the logs that caused crashes:
      # ** (FunctionClauseError) no function clause matching in 
      # EatfairWeb.Live.Components.AddressAutocomplete.handle_event/3
      # Parameters: %{"_target" => ["undefined"]}

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          id: "homepage-address-autocomplete",
          value: "",
          target: nil,
          suggestions: [],
          query: "",
          show_suggestions: false,
          selected_index: -1,
          class:
            "block w-full rounded-lg border-0 bg-white px-4 py-4 text-gray-900 shadow-lg ring-1 ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-orange-500 text-lg",
          event: "location_selected",
          placeholder: "Amsterdam",
          __changed__: %{}
        }
      }

      # FIXED: This exact parameter pattern that crashed now works
      crash_params = %{"_target" => ["undefined"]}

      # Should NOT crash - should handle gracefully
      {:noreply, result_socket} =
        AddressAutocomplete.handle_event("input_change", crash_params, socket)

      # Should maintain safe state with empty query (no value provided)
      assert result_socket.assigns.query == ""
      assert result_socket.assigns.suggestions == []
      assert result_socket.assigns.show_suggestions == false
    end

    test "handles normal input_change correctly" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          id: "homepage-address-autocomplete",
          value: "",
          target: nil,
          suggestions: [],
          query: "",
          show_suggestions: false,
          selected_index: -1,
          class: "",
          event: "location_selected",
          placeholder: "Amsterdam",
          __changed__: %{}
        }
      }

      # This should work - matches the existing function clause
      normal_params = %{"value" => "Amsterdam"}

      {:noreply, result_socket} =
        AddressAutocomplete.handle_event("input_change", normal_params, socket)

      assert result_socket.assigns.query == "Amsterdam"
    end
  end

  describe "after fix: defensive input_change handling" do
    test "handles malformed input_change parameters gracefully" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          id: "homepage-address-autocomplete",
          value: "",
          target: nil,
          suggestions: [],
          query: "",
          show_suggestions: false,
          selected_index: -1,
          class: "",
          event: "location_selected",
          placeholder: "Amsterdam",
          __changed__: %{}
        }
      }

      # After fix, these should ALL return {:noreply, socket} without crashing
      malformed_cases = [
        %{"_target" => ["undefined"]},
        %{"_target" => "not_a_list"},
        %{"unknown_key" => "unknown_value"},
        # empty map
        %{},
        %{"value" => nil},
        # non-string
        %{"value" => 123},
        # wrong type
        %{"value" => []}
      ]

      for params <- malformed_cases do
        {:noreply, result_socket} =
          AddressAutocomplete.handle_event("input_change", params, socket)

        # Should not crash and should maintain safe state
        assert is_binary(result_socket.assigns.query)
        assert is_list(result_socket.assigns.suggestions)
      end
    end

    test "extracts value from different parameter structures" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          id: "test",
          value: "",
          target: nil,
          suggestions: [],
          query: "old_query",
          show_suggestions: false,
          selected_index: -1,
          class: "",
          event: "location_selected",
          placeholder: "",
          __changed__: %{}
        }
      }

      # Test various ways value might be passed
      test_cases = [
        {%{"value" => "Amsterdam"}, "Amsterdam"},
        {%{"_target" => ["input"], "value" => "Amsterdam"}, "Amsterdam"},
        # Should default to empty
        {%{"_target" => ["undefined"]}, ""},
        # Should default to empty
        {%{}, ""}
      ]

      for {params, expected_query} <- test_cases do
        {:noreply, result_socket} =
          AddressAutocomplete.handle_event("input_change", params, socket)

        assert result_socket.assigns.query == expected_query
      end
    end
  end
end
